/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_BalanceUp_Headline]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
/*
	Task: Sumup balance amount for headline account
	Location: DBTXN.bodb02

	Revision: 
		- 20190910@Patrick: Init [RedmineId: #118818]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		- 20220727@Patrick: Support new transid [Redmine: #175666]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__custList (keyId int PRIMARY KEY IDENTITY(1,1), custid int)
	DECLARE @rc INT, @r INT
	DECLARE @__tryCnt INT = 0, @__errorCode INT, @__errorMessage varchar(200) = '', @__doing varchar(300)

	INSERT INTO #__custList(custid)
	SELECT custid
	FROM dbo.balanceTable_tmp WITH(NOLOCK)
	WHERE roleid = 0

	SET @rc = @@ROWCOUNT
	SET @r = 1

	--DECLARE @__tempTransIds TABLE (transid BIGINT)
	DECLARE @__tempCustIds TABLE(custid INT)

	DECLARE @delayTimeValue VARCHAR(50)
	SET @delayTimeValue = '00:00:01.500'

	DECLARE @transIds VARCHAR(MAX)
	SET @transIds = ''

	WHILE @r <= @rc
	BEGIN
	
		DELETE FROM @__tempCustIds

		SET @transIds = NULL

		INSERT INTO @__tempCustIds(custid)
		SELECT t.custid
		FROM #__custList t WITH (NOLOCK)
		WHERE keyId >= @r AND keyId < @r + 200

		SELECT @transIds = COALESCE(@transIds + '^' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
		FROM dbo.Transfer b WITH(NOLOCK)
		WHERE b.custid IN (SELECT t.custId FROM @__tempCustIds t)
			AND b.winlostdate < @winlostdate
	
		--handle case duplicated PK
		SELECT @__tryCnt = 0, @__errorCode = 0, @__errorMessage = ''
		WHILE 1 = 1
		BEGIN
			BEGIN TRY
				--//.....
				DELETE FROM dbo.balanceTable_tmp WHERE custid IN (SELECT t.custid FROM @__tempCustIds t)

				BREAK

			END TRY
			BEGIN CATCH
				SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1

				--write logs:
				SET @__doing = 'Task_BalanceUp_Headline: duplicated transid (1). Err: ' + @__errorMessage
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

					WAITFOR DELAY '00:00:01:001' -- Task_BalanceUp_Headline: duplicated transid then waitfor to retry
				END
				ELSE
				BEGIN
					--other exception then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END

			END CATCH
		END

		EXEC dbo.ExecRep_07 @custids = '', @custid = 0, @roleid = 111, @winlostdate = @winlostdate, @transIds = @transIds

		SET @r = @r + 200

		SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key1')
		WAITFOR DELAY @delayTimeValue

	END

	DROP TABLE #__custList
END
GO
