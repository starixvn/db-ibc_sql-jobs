/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Pick] 
	@top INT
	, @round int = 1
AS
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
*/
BEGIN
	SET NOCOUNT ON
	
	replication_latency:
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.SystemSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running @DBTP so skip check balance....'
		RETURN
	END

	IF EXISTS (
		SELECT TOP 1 1
		FROM DBAWS.bodb02.dbo.SystemSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running @AWS so skip check balance....'
		RETURN
	END

	DECLARE @__movebetDateTP SMALLDATETIME, @__movebetDateAWS SMALLDATETIME
	EXEC [dbo].[NAP_Admin_GetMovebetDate] @MovebetDate = @__movebetDateTP OUTPUT

	EXEC DBAWS.bodb02.[dbo].[NAP_Admin_GetMovebetDate] @MovebetDate = @__movebetDateAWS OUTPUT

	IF @__movebetDateAWS <> @__movebetDateTP
	BEGIN
		DECLARE @__message VARCHAR(500)
		SET @__message = 'DBTP: ' + CONVERT(varchar(10), @__movebetDateTP, 121) + ' / ' + 'DBAWS: ' + CONVERT(varchar(10), @__movebetDateAWS, 121)
		PRINT @__message
		WAITFOR DELAY '00:00:30:000'
		GOTO replication_latency
	END

	--clear all data for next round @dbtp
	DELETE FROM dbo.Task_AWS_Balance_Check

	--clear all data for next round @aws
	EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_CustList_Modify @mode = 'delete', @custids = '', @tableName = 'Task_AWS_Balance_Check'

	DECLARE @__custids VARCHAR(MAX) = NULL
	IF @round = 1 -- pick top n cust need to check
	BEGIN
		--clear all data for next schedule
		DELETE FROM dbo.Task_AWS_Balance_Check_MaxIdList
		DELETE FROM DBAWS.bodb02.dbo.Task_AWS_Balance_Check_MaxIdList
		
		--get max trans
		INSERT INTO dbo.Task_AWS_Balance_Check_MaxIdList(Id, tableName)
		SELECT MAX(transId) AS Id, 'bettrans' AS TableName FROM dbo.bettrans WITH(NOLOCK) UNION ALL
		SELECT MAX(transId) AS Id, 'transfer' AS TableName FROM dbo.Transfer WITH(NOLOCK) UNION ALL
		SELECT MAX(transId) AS Id, 'bettransLC' AS TableName FROM dbo.bettransLC WITH(NOLOCK) UNION ALL
		SELECT MAX(transId) AS Id, 'bettransRnG' AS TableName FROM dbo.bettransRnG WITH(NOLOCK) UNION ALL
		SELECT MAX(translogid) AS Id, 'translog' AS TableName FROM dbo.translog WITH(NOLOCK)

		--import list cust check to @aws
		INSERT INTO DBAWS.bodb02.dbo.Task_AWS_Balance_Check_MaxIdList(Id, tableName)
		SELECT Id, tableName 
		FROM dbo.Task_AWS_Balance_Check_MaxIdList

		--check bet
		DECLARE @__maxtransId BIGINT, @__maxawstransId BIGINT
		SELECT @__maxtransId = MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettrans'
		SELECT @__maxawstransId = MAX(transid) FROM DBAWS.bodb02.dbo.bettrans WITH(NOLOCK)

		IF @__maxtransId - @__maxawstransId > 5000
		BEGIN
			WAITFOR DELAY '00:01:00:000' --replication latency on dbbal
			GOTO replication_latency
		END

		--check transfer
		DECLARE @__maxTransferTransId BIGINT, @__maxawsTransferTransId BIGINT
		SELECT @__maxTransferTransId = MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettrans'
		SELECT @__maxawsTransferTransId = MAX(transid) FROM DBAWS.bodb02.dbo.transfer WITH(NOLOCK)

		IF @__maxTransferTransId - @__maxawsTransferTransId > 5000
		BEGIN
			WAITFOR DELAY '00:01:00:000' --replication latency on dbbal
			GOTO replication_latency
		END

		WAITFOR DELAY '00:00:03:000'

		--scan all for weekly
		DECLARE @today DATETIME = GETDATE()
		IF DATEPART(WEEKDAY, @today) = 2 -- only scan all cust on Monday
		BEGIN
			IF NOT EXISTS (
				SELECT TOP 1 1 FROM dbo.SystemSettings 
				WHERE VName = 'AWS_DBTP_Check_All' 
					AND CONVERT(date, VValue) = CONVERT(DATE, @today)
			)
			BEGIN
				UPDATE dbo.SystemSettings 
				SET VValue = CONVERT(VARCHAR(50), @today, 121)
				WHERE VName = 'AWS_DBTP_Check_All'

				TRUNCATE TABLE dbo.Task_AWS_Balance_All_Cust_Check
				INSERT INTO dbo.Task_AWS_Balance_All_Cust_Check(custid)
				SELECT custid FROM dbo.bettrans WITH(NOLOCK) WHERE transid <= @__maxtransId
				GROUP BY custid
				UNION
				SELECT custid FROM dbo.Transfer WITH(NOLOCK) WHERE transid <= @__maxTransferTransId
				GROUP BY custid
			END
		END

		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.Task_AWS_Balance_All_Cust_Check
		)
		BEGIN
			DELETE TOP(@top)
			FROM dbo.Task_AWS_Balance_All_Cust_Check
			OUTPUT DELETED.custid INTO dbo.Task_AWS_Balance_Check
			
		END
		ELSE --pic random
		BEGIN
			--get last top n lastest ticket
			INSERT INTO dbo.Task_AWS_Balance_Check(custid)
			SELECT DISTINCT custid
			FROM (
				SELECT TOP (@top) custid, transid
				FROM dbo.bettrans WITH(NOLOCK) WHERE transid <= @__maxtransId
				ORDER BY transdate DESC
			)t 
			UNION
			SELECT DISTINCT custid
			FROM (
				SELECT TOP (@top) custid, transid
				FROM dbo.Transfer WITH(NOLOCK) WHERE transid <= @__maxTransferTransId
				ORDER BY transid DESC
			)t 
		END

		--import list cust check to @aws
		SET @__custids = NULL
		SELECT @__custids = COALESCE(@__custids + '^' + CAST(custid AS VARCHAR(50)), CAST(custid AS VARCHAR(50)))
		FROM dbo.Task_AWS_Balance_Check

		EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_CustList_Modify @mode = 'insert'
			, @custids = @__custids
			, @tableName = 'Task_AWS_Balance_Check'

	END
	ELSE
	BEGIN
		INSERT INTO dbo.Task_AWS_Balance_Check(custid)
		SELECT custid
		FROM dbo.Task_AWS_Balance_Check_Verify

		IF @@ROWCOUNT > 0
		BEGIN
			--import list cust to check to @aws
			SET @__custids = NULL
			SELECT @__custids = COALESCE(@__custids + '^' + CAST(custid AS VARCHAR(50)), CAST(custid AS VARCHAR(50)))
			FROM dbo.Task_AWS_Balance_Check

			EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_CustList_Modify 
				@mode = 'insert'
				, @custids = @__custids
				, @tableName = 'Task_AWS_Balance_Check'
		END
	END
END
GO
