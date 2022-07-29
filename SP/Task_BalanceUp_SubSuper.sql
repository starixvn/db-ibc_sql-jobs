/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_SubSuper]
    @winlostdate smalldatetime,
    @preview bit = 0
AS
/*
	Created by:[]
	Date:
	Task: 
	DB: DBTXN/BODB02
	Revisions:				
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
		- 20220727@Patrick: Support new transid [Redmine: #175666]

*/
create table #srecommend (KeyID int PRIMARY KEY IDENTITY(1,1), srecommend int, ticketCount int)

-- Get ticketcount per Super
insert into #srecommend (srecommend, ticketCount)
select srecommend, SUM(ticketCount)
FROM balanceTable_tmp
WHERE roleid IN (3,4)
GROUP BY srecommend
ORDER BY 2 DESC

Declare @custid_list varchar(2100), @cnt int, @custid_cnt int, @rc int, @r int
Declare @keyID int, @custid_listustid int, @srecommend int, @ticketCount int
DECLARE @__tryCnt INT = 0, @__errorCode INT, @__errorMessage varchar(200) = '', @__doing varchar(300)

SET @r = 1
NewSuperList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddSuper:
SELECT @keyID = keyID, @srecommend = srecommend, @ticketCount = ticketCount
FROM #srecommend 
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
    SET @custid_list = @custid_list + CAST(@srecommend as varchar(40)) + ','
    SET @cnt = @cnt + @ticketCount
    SET @custid_cnt = @custid_cnt + 1

    DELETE FROM #srecommend WHERE KeyID = @keyID
END

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 5 AND @rc > 0 GOTO AddSuper -- add next Super into list until condition meet

IF @custid_cnt > 0
BEGIN
    SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

    IF @preview = 1
    BEGIN
        PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total srecommend : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
        SET @r = @r + 1
    END
    ELSE
    BEGIN
        --insert processing list
        EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = @custid_list
        WAITFOR DELAY '000:00:01:000'

		--handle case duplicated PK
		SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
		WHILE 1 = 1
		BEGIN
			BEGIN TRY
				--//.....
				DELETE FROM dbo.balanceTable_tmp
				WHERE srecommend IN (select value from STRING_SPLIT(@custid_list, ','))
				
				BREAK

			END TRY
			BEGIN CATCH
				SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

				--write logs:
				SET @__doing = 'Task_BalanceUp_SubSuper: duplicated transid (1). Err: ' + @__errorMessage
				EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

				IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
				BEGIN
					IF @__tryCnt = 5
					BEGIN
						--duplicated PK reach to limitation then throw error and quit job
						RAISERROR(@__errorMessage, 16, 1)
						RETURN
					END

					--Send notification to dba
					EXEC dbo.DBA_Task_Send_SimpleNotifyMessageToDBA
						@SubjectName = 'Urgently!!! BU - Notification',
						@MessageName = @__doing

					WAITFOR DELAY '00:00:01:333' -- Task_BalanceUp_SubSuper: duplicated transid then waitfor to retry
				END
				ELSE
				BEGIN
					--other exception then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

			END CATCH
		END

        EXEC dbo.ExecRep_07 @custid_list, 0, 44, @winlostdate
        --COMMIT TRANSACTION

        --WAITFOR DELAY '000:00:01.500'
        --delete processing list
        EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = @custid_list
    END
END

IF @rc > 0 GOTO NewSuperList

NoMoreSuper:
