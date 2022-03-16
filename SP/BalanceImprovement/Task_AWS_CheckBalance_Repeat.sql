/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Repeat]
AS
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.SystemSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running @DBTP so skip check balance....'
		WAITFOR DELAY '00:03:00:000' -- check bal of aws --> waitfor MBU is running...
		--DELETE FROM dbo.Task_AWS_Balance_Check_Verify
		RETURN
	END

	IF EXISTS (
		SELECT TOP 1 1
		FROM DBAWS.bodb02.dbo.SystemSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running @AWS so skip check balance....'
		WAITFOR DELAY '00:03:00:000' -- check bal of aws --> waitfor MBU is running...
		--DELETE FROM dbo.Task_AWS_Balance_Check_Verify
		RETURN
	END

	DECLARE @__maxtransId BIGINT, @__maxawstransId BIGINT
	SELECT @__maxtransId = MAX(Id) FROM dbo.Task_AWS_Balance_Check_MaxIdList WHERE tableName = 'bettrans'
	SELECT @__maxawstransId = MAX(transid) FROM DBAWS.bodb02.dbo.bettrans WITH(NOLOCK)

	IF @__maxtransId - @__maxawstransId > 5000
	BEGIN
		PRINT 'Replication latency on dbbal....'
		WAITFOR DELAY '00:00:15:000' --replication latency on dbbal
		RETURN
	END

	CREATE TABLE #__balanceDBTP(custid int, balance money)
	CREATE TABLE #__balanceAWS(custid int, balance money)
	CREATE TABLE #__balance(custid int, diff money)

	--for next round, we should scan all data from Task_AWS_Balance_Check_Verify
	EXEC [dbo].[Task_AWS_CheckBalance_Pick] @top = 0, @round = 2

	IF NOT EXISTS (
		SELECT TOP 1 1 FROM dbo.Task_AWS_Balance_Check
	)
	BEGIN
		print 'no data'
		GOTO No_More_Data
	END

	INSERT INTO #__balanceDBTP(custid, balance)
	EXEC dbo.Task_AWS_CheckBalance_Get

	INSERT INTO #__balanceAWS(custid, balance)
	EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_Get

	INSERT INTO #__balance(custid, diff)
	SELECT t.custid, (ISNULL(t.balance, 0) - ISNULL(tt.balance, 0)) as diff
	FROM #__balanceDBTP t
	INNER JOIN #__balanceAWS tt ON t.custid = tt.custid
	WHERE ISNULL(t.balance, 0) <> ISNULL(tt.balance, 0)

	UPDATE cb
	SET roundVerified = CASE ISNULL(q.diff, 0)	WHEN cb.diffBalance THEN roundVerified + 1 -- if Diff value remain the same amount, increase counter, ELSE reset counter
									ELSE 0 END,
		diffBalance = ISNULL(q.diff, 0) -- update new Diff
	FROM dbo.Task_AWS_Balance_Check_Verify cb
		LEFT JOIN #__balance q ON cb.custid = q.custid

	DELETE FROM dbo.Task_AWS_Balance_Check_Verify
	WHERE DiffBalance = 0 AND roundVerified >= 3 -- remove record, if compare and no diff for 3 times

	No_More_Data:
	IF NOT EXISTS (SELECT 1 FROM dbo.Task_AWS_Balance_Check_Verify)
	BEGIN
		-- GENERATE ERROR TO STOP PROCESS.
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	ELSE IF EXISTS (SELECT 1 FROM dbo.Task_AWS_Balance_Check_Verify WHERE roundVerified >= 5)
	BEGIN
		PRINT 'Start FixOne'
		Declare @i int, @maxRN int, @custid int, @roundVerified int
			, @balancedbtp money, @balanceaws money, @__diffAmt money
	
		CREATE TABLE #c (RN int IDENTITY(1,1) PRIMARY KEY, custid int, roundVerified int, diffAmt money)
		INSERT INTO #c (custid, roundVerified, diffAmt) SELECT custid, roundVerified, diffBalance 
		FROM dbo.Task_AWS_Balance_Check_Verify WHERE roundVerified >= 5
		SELECT @maxRN = @@ROWCOUNT
		SET @i = 1
	
		WHILE @i <= @maxRN
		BEGIN
			SELECT @custid = custid, @roundVerified = roundVerified, @__diffAmt = diffAmt FROM #c WHERE RN = @i
		
			EXEC dbo.Task_AWS_CheckBalance_Check_One @custid = @custid, @balance = @balancedbtp OUTPUT
			EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_Check_One @custid = @custid, @balance = @balanceaws OUTPUT
		
			IF @balancedbtp <> @balanceaws and ((@balancedbtp - @balanceaws) = @__diffAmt)
			BEGIN
				DELETE FROM dbo.Task_AWS_Balance_Check_Verify WHERE custid = @custid
				EXEC dbo.Task_AWS_CheckBalance_Check_One_Logs @custid = @custid
				-- LOG
				INSERT INTO dbo.Task_AWS_Balance_Check_Problem (custid, username, diffBalance, IsFixed, roundVerified, Remark)
				SELECT @custid, username, (@balancedbtp - @balanceaws), 0, @roundVerified, 'roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE currency WHEN 20 THEN ' UUS' ELSE '' END
				FROM dbo.custInfo with (nolock)
				WHERE custid = @custid

			END
			ELSE
			PRINT 'need to review!!!'
		
			SET @i = @i + 1
		END
	END
END