/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_BalanceUp_CalculateBalanceUpDate
/*
    Created by: 20220602@Patrick
    Task: Task_BalanceUp_CalculateBalanceUpDate
    DB: DBTXN/BODB02 

	Revisions:
		- 20220602@Patrick: Revise BalanceUp background to support 247 [Redmine:#173554]
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @__currBalanceUpDate SMALLDATETIME
		, @__fdate SMALLDATETIME
		, @__doing VARCHAR(300)
		, @__movebetdate SMALLDATETIME

	SET @__doing = 'Task_BalanceUp_CalculateBalanceUpDate: Starting'
	EXEC bodb_CustomerLog.dbo.Task_UserLog_SendMessage @UserID = 25520, @Doing = @__doing

	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.MBUSettings
		WHERE VName = 'BeingBalanceUpDate' AND VValue IS NULL
	)
	BEGIN
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__currBalanceUpDate OUTPUT
		SET @__fdate = DATEADD(DAY, 7, @__currBalanceUpDate)
		PRINT '@fdate = ' + CONVERT(VARCHAR(10), @__fdate, 120)

	END

	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT
	IF @__fdate IS NULL OR @__fdate > @__movebetdate
	BEGIN
		RAISERROR ('ERROR: Please check a balance-up date value. (1)', 16, 1);
		RETURN
	END

	SET @__doing = 'Task_BalanceUp_CalculateBalanceUpDate: done calculating being balance up date, @__currBalanceUpDate: '+ CONVERT(VARCHAR(10), @__currBalanceUpDate, 121) +', @__fdate: ' + CONVERT(VARCHAR(10), @__fdate, 121)
	EXEC bodb_CustomerLog.dbo.Task_UserLog_SendMessage @UserID = 25520, @Doing = @__doing

	--verify with old way
	DECLARE @__verifyDate SMALLDATETIME
	SELECT TOP(1) @__verifyDate = DATEADD(DAY, 7, winlostdate)
	FROM dbo.Transfer WITH(NOLOCK)
	WHERE bettype = 20000
	ORDER BY transid

	IF @__verifyDate <> @__fdate
	BEGIN
		RAISERROR ('ERROR: Please check a balance-up date value. (2)', 16, 1);
		RETURN
	END

	--verify with task_archivedate
	SELECT @__verifyDate = MAX(winlostdate)
	FROM dbo.Task_ArchiveDate
	IF DATEADD(DAY, 1, @__verifyDate) <> @__fdate
	BEGIN
		RAISERROR ('ERROR: Please check a balance-up date value. (3)', 16, 1);
		RETURN
	END

	--turn on starting BU process
	SET @__doing = 'Task_BalanceUp_CalculateBalanceUpDate: Starting update BeingBalanceUpDate flag, @fdate: ' + CONVERT(VARCHAR(10), @__fdate, 121)
	EXEC bodb_CustomerLog.dbo.Task_UserLog_SendMessage @UserID = 25520, @Doing = @__doing

	--**update being balanceUp date flag ==> the purpose for which process need to check balanceUp processing
	EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @__fdate, @keyFlag = 11, @tableName = 'MBUSettings'

	SET @__doing = 'Task_BalanceUp_CalculateBalanceUpDate: Ending update BeingBalanceUpDate flag, @fdate: ' + CONVERT(VARCHAR(10), @__fdate, 121)
	EXEC bodb_CustomerLog.dbo.Task_UserLog_SendMessage @UserID = 25520, @Doing = @__doing

	SET @__doing = 'Task_BalanceUp_CalculateBalanceUpDate: Ending'
	EXEC bodb_CustomerLog.dbo.Task_UserLog_SendMessage @UserID = 25520, @Doing = @__doing
END
GO
