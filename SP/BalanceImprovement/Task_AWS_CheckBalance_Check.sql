/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_AWS_CheckBalance_Check]
AS
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
		- 20230104@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.SystemSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running so skip check balance....'
		--DELETE FROM dbo.Task_AWS_Balance_Check_Verify
		RETURN
	END

	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.MBUSettings WHERE VName IN ('isMovingBet_Local', 'isArchivingBet_Local') AND VValue = '1'
	)
	BEGIN
		PRINT 'MBU is running so skip check balance....'
		--DELETE FROM dbo.Task_AWS_Balance_Check_Verify
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Task_AWS_Balance_Check_Verify)
	BEGIN

		CREATE TABLE #__balanceDBTP(custid int, balance money)
		CREATE TABLE #__balanceAWS(custid int, balance money)
		CREATE TABLE #__balance(custid int, diff money)
		CREATE TABLE #__balance2nd(custid int, diff money)

		INSERT INTO #__balanceDBTP(custid, balance)
		EXEC dbo.Task_AWS_CheckBalance_Get

		INSERT INTO #__balanceAWS(custid, balance)
		EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_Get

		INSERT INTO #__balance(custid, diff)
		SELECT t.custid, (ISNULL(t.balance, 0) - ISNULL(tt.balance, 0)) as diff
		FROM #__balanceDBTP t
		LEFT JOIN #__balanceAWS tt ON t.custid = tt.custid
		WHERE ISNULL(t.balance, 0) <> ISNULL(tt.balance, 0)

		DELETE FROM #__balanceDBTP
		DELETE FROM #__balanceAWS

		INSERT INTO #__balanceDBTP(custid, balance)
		EXEC dbo.Task_AWS_CheckBalance_Get

		INSERT INTO #__balanceAWS(custid, balance)
		EXEC DBAWS.bodb02.dbo.Task_AWS_CheckBalance_Get

		INSERT INTO #__balance2nd(custid, diff)
		SELECT t.custid, (ISNULL(t.balance, 0) - ISNULL(tt.balance, 0)) as diff
		FROM #__balanceDBTP t
			LEFT JOIN #__balanceAWS tt ON t.custid = tt.custid
		WHERE ISNULL(t.balance, 0) <> ISNULL(tt.balance, 0)

		INSERT INTO dbo.Task_AWS_Balance_Check_Verify(custid, roundVerified, MaxRowVersion, DiffBalance)
		SELECT t.custid, 0, 0, tt.diff
		FROM #__balance t
		INNER JOIN #__balance2nd tt ON t.custid = tt.custid

	END
END