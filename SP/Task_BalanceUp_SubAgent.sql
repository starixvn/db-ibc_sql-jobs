/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp_SubAgent]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
/*
	Created by:[]
	Date:
	Task: daily summary
	DB: DBTXN/BODB02
	Revisions:
		- .....
		- 20190312@Patrick: Fix issue always scan temp table #custid [RedmineID: #110106]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]				
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
		- 20220727@Patrick: Support new transid [Redmine: #175666]

*/
CREATE TABLE #recommend (KeyID int PRIMARY KEY IDENTITY(1,1), recommend int, ticketCount int)
CREATE TABLE #custid (KeyID int PRIMARY KEY IDENTITY(1,1), custid int, ticketCount int)
Declare @rKeyID int, @cKeyID int
Declare @custid_list varchar(2100), @cnt int, @custid_cnt int, @rc int, @r int
Declare @keyID int, @custid_listustid int, @recommend int, @ticketCount int
Declare @custid int, @BAL_TransID bigint
DECLARE @__tryCnt INT = 0, @__errorCode INT, @__errorMessage varchar(200) = '', @__doing varchar(300)

CREATE TABLE #custid_nobet (KeyID int PRIMARY KEY IDENTITY(1,1), custid int, BAL_transid bigint)

;WITH C AS (SELECT custid, 
	COUNT(*) AS Ticket_Count, 
	SUM(CASE WHEN bettype = 20000 THEN 1 ELSE 0 END) AS BAL_Count,
	MAX(CASE WHEN bettype = 20000 THEN transid ELSE 0 END) AS BAL_TransID
	FROM dbo.Transfer WITH (NOLOCK)
	WHERE winlostdate < @winlostdate
	GROUP BY custid
)
INSERT INTO #custid_nobet (custid, BAL_transid)
SELECT c.custid, c.BAL_TransID
FROM C
	INNER JOIN dbo.BalanceTable_tmp b WITH (NOLOCK) ON C.custid = b.custid AND b.roleid = 1
	WHERE C.BAL_Count = 1 AND C.Ticket_Count = 1 -- have only 1 row, and it's BAL
ORDER BY c.custid

SET @rc = @@ROWCOUNT
SET @r = 1

DECLARE @tblNoBetTmp TABLE (custid INT, transid BIGINT)
DECLARE @delayTimeValue VARCHAR(50)
SET @delayTimeValue = '00:00:01.500'

DECLARE @transIds VARCHAR(MAX)
SET @transIds = ''

WHILE @r <= @rc
BEGIN
	
	DELETE FROM @tblNoBetTmp
	SET @transIds = NULL

	INSERT INTO @tblNoBetTmp(custid, transid)
	SELECT custid, BAL_transid
	FROM #custid_nobet WITH (NOLOCK) WHERE KeyID BETWEEN @r AND @r + 1000

	--handle case duplicated PK
	SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
	WHILE 1 = 1
	BEGIN
		BEGIN TRY
			--//.....
			DELETE FROM dbo.balanceTable_tmp WHERE custid IN (SELECT t.custid FROM @tblNoBetTmp t)
			BREAK

		END TRY
		BEGIN CATCH
			SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

			--write logs:
			SET @__doing = 'Task_BalanceUp_SubAgent: duplicated transid (1). Err: ' + @__errorMessage
			EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

			IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
			BEGIN
				IF @__tryCnt = 3
				BEGIN
					--duplicated PK reach to limitation then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

				--Send notification to dba
				EXEC [dbo].[DBA_Task_Send_SimpleNotifyMessageToDBA] 
					@SubjectName = 'Urgently!!! BU - Notification',
					@MessageName = @__doing

				WAITFOR DELAY '00:00:01:001' -- Task_BalanceUp_SubAgent: duplicated transid then waitfor to retry
			END
			ELSE
			BEGIN
				--other exception then throw error and quit job
				RAISERROR(@__errorMessage, 16, 1)
				RETURN
			END

		END CATCH
	END
	
	SELECT @transIds = COALESCE(@transIds + '^' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
	FROM @tblNoBetTmp

	EXEC dbo.ExecRep_07 @custids = '', @custid = 0, @roleid = 111, @winlostdate = @winlostdate, @transIds = @transIds

	SET @r = @r + 1000

	SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key1')
	WAITFOR DELAY @delayTimeValue

END

insert into #recommend (recommend, ticketCount)
select recommend, SUM(ticketCount)
FROM balanceTable_tmp
WHERE roleid IN (1,2)
GROUP BY recommend
ORDER BY 2, 1 --DESC


SET @rKeyID = 1
SET @r = 1
NewAgentList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddAgent:
SELECT @keyID = keyID, @recommend = recommend, @ticketCount = ticketCount
FROM #recommend 
WHERE keyID = @rKeyID
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@recommend as varchar(40)) + ','
	SET @cnt = @cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	--DELETE FROM #recommend WHERE KeyID = @keyID
	SET @rKeyID = @rKeyID + 1
END

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 GOTO AddAgent -- add next agent into list until condition meet

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total recommend : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN

		--insert processing list
		EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = @custid_list
		SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key2')
		WAITFOR DELAY @delayTimeValue

		--BEGIN TRANSACTION
		--handle case duplicated PK
		SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
		WHILE 1 = 1
		BEGIN
			BEGIN TRY
				--//.....
				DELETE FROM dbo.balanceTable_tmp
				WHERE recommend IN (select value from STRING_SPLIT(@custid_list, ','))
				
				BREAK

			END TRY
			BEGIN CATCH
				SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

				--write logs:
				SET @__doing = 'Task_BalanceUp_SubAgent: duplicated transid (2). Err: ' + @__errorMessage
				EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

				IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
				BEGIN
					IF @__tryCnt = 3
					BEGIN
						--duplicated PK reach to limitation then throw error and quit job
						RAISERROR(@__errorMessage, 16, 1)
						RETURN
					END

					--Send notification to dba
					EXEC [dbo].[DBA_Task_Send_SimpleNotifyMessageToDBA] 
						@SubjectName = 'Urgently!!! BU - Notification',
						@MessageName = @__doing

					WAITFOR DELAY '00:00:01:001' -- Task_BalanceUp_SubAgent: duplicated transid then waitfor to retry
				END
				ELSE
				BEGIN
					--other exception then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

			END CATCH
		END

		EXEC dbo.ExecRep_07 @custid_list, 0, 22, @winlostdate
		--COMMIT TRANSACTION

		--WAITFOR DELAY '000:00:01.500'
		--delete processing list
		EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = @custid_list
	END
END

IF IsNull(@ticketCount,0) > 5000 GOTO PickNextAgent -- if ticketCount per 1 agent over 5000, go to loop for each custid
IF @rc > 0 GOTO NewAgentList

PickNextAgent:
SELECT @keyID = keyID, @recommend = recommend, @ticketCount = ticketCount
FROM #recommend
WHERE keyID = @rKeyID
--ORDER BY ticketCount

IF @@ROWCOUNT = 0 GOTO NoMoreAgent -- no more agent

truncate table #custid
insert into #custid (custid, ticketCount)
SELECT custid, ticketCount
FROM dbo.BalanceTable_tmp
WHERE roleid = 1 AND recommend = @recommend --AND TicketCount > 5
SET @cKeyID = 1

NewCustIDList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddCustID:
SELECT @keyID = keyID, @custid_listustid = custid, @ticketCount = ticketCount
FROM #custid
WHERE keyID = @cKeyID
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@custid_listustid as varchar(40)) + ','
	SET @cnt = @cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	DELETE FROM #custid WHERE KeyID = @keyID
END
SET @cKeyID = @cKeyID + 1

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 GOTO AddCustID -- loop for add another customer into list

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total custid : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		--insert processing list
		EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = @custid_list

		SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key3')
		WAITFOR DELAY @delayTimeValue

		--handle case duplicated PK
		SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
		WHILE 1 = 1
		BEGIN
			BEGIN TRY
				--//.....

				DELETE FROM dbo.balanceTable_tmp
				WHERE custid IN (select value from STRING_SPLIT(@custid_list, ','))

				BREAK

			END TRY
			BEGIN CATCH
				SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

				--write logs:
				SET @__doing = 'Task_BalanceUp_SubAgent: duplicated transid (3). Err: ' + @__errorMessage
				EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

				IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
				BEGIN
					IF @__tryCnt = 3
					BEGIN
						--duplicated PK reach to limitation then throw error and quit job
						RAISERROR(@__errorMessage, 16, 1)
						RETURN
					END

					--Send notification to dba
					EXEC [dbo].[DBA_Task_Send_SimpleNotifyMessageToDBA] 
						@SubjectName = 'Urgently!!! BU - Notification',
						@MessageName = @__doing

					WAITFOR DELAY '00:00:01:001' -- Task_BalanceUp_SubAgent: duplicated transid then waitfor to retry
				END
				ELSE
				BEGIN
					--other exception then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

			END CATCH
		END

		EXEC dbo.ExecRep_07 @custid_list, @recommend, 11, @winlostdate
		--COMMIT TRANSACTION

		--WAITFOR DELAY '000:00:10.000'
		--delete processing list
		EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = @custid_list
	END
END

IF @rc > 0 GOTO NewCustIDList -- still not empty, loop for next list of customer

--DELETE FROM #recommend WHERE recommend = @recommend
SET @rKeyID = @rKeyID + 1

IF @preview = 1
BEGIN
	SELECT @ticketCount = ticketCount
	FROM dbo.balanceTable_tmp
	WHERE custid = @recommend

	PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@ticketCount as varchar(40)) + '   ' + CAST(@recommend as varchar(40))
	SET @r = @r + 1
END
ELSE
BEGIN
	--insert processing list
	EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = @custid_list

	SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key4')
	WAITFOR DELAY @delayTimeValue

	--handle case duplicated PK
	SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
	WHILE 1 = 1
	BEGIN
		BEGIN TRY
			--//.....
			DELETE FROM dbo.balanceTable_tmp
			WHERE recommend = @recommend

			BREAK

		END TRY
		BEGIN CATCH
			SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

			--write logs:
			SET @__doing = 'Task_BalanceUp_SubAgent: duplicated transid (4). Err: ' + @__errorMessage
			EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

			IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
			BEGIN
				IF @__tryCnt = 3
				BEGIN
					--duplicated PK reach to limitation then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

				--Send notification to dba
				EXEC [dbo].[DBA_Task_Send_SimpleNotifyMessageToDBA] 
					@SubjectName = 'Urgently!!! BU - Notification',
					@MessageName = @__doing

				WAITFOR DELAY '00:00:01:001' -- Task_BalanceUp_SubAgent: duplicated transid then waitfor to retry
			END
			ELSE
			BEGIN
				--other exception then throw error and quit job
				RAISERROR(@__errorMessage, 16, 1)
				RETURN
			END

		END CATCH
	END

	EXEC dbo.ExecRep_07 '', @recommend, 2, @winlostdate
	--COMMIT TRANSACTION

	--WAITFOR DELAY '000:00:10.00'
	EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = @custid_list
END

GOTO PickNextAgent -- no more customer, loop for next agent

NoMoreAgent:
GO

GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUp_SubAgent] TO [vnteam] AS [dbo]
GO


