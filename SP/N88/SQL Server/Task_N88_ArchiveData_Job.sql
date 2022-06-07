/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_ArchiveData_Job]
AS

/*
	Created: 20220222@Percy
	DB: DBN88-bodb_N88
	Task: Job - Archive data for TpBetRecord

	Revisions:
		- 20220222@Percy: Initialize SP [RedmineID: #167823]
		- 20220601@Percy: Add step send mail if data is changed [RedmineID: #173790]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @WinlostDate SMALLDATETIME, @LastArchiveDate SMALLDATETIME = dbo.N88_f_GetSystemSettings('ArchiveData_Date')
	DECLARE @tmpDate SMALLDATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0) -- first day of last month

	-- Step 1: Copy data
	SELECT @WinlostDate = @LastArchiveDate 
	WHILE @WinlostDate < @tmpDate
	BEGIN
		EXEC dbo.Task_N88_Archive_CopyData @WinlostDate = @WinlostDate

		WAITFOR DELAY '00:00:00.280'

		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	-- Step 2: Check rowcount
	DECLARE @rowcount INT, @new_rowcount INT, @Msg VARCHAR(200)
	SELECT @WinlostDate = @LastArchiveDate
	WHILE @WinlostDate < @tmpDate
	BEGIN
		SELECT @rowcount = COUNT(1) FROM dbo.TpBetRecord WITH (NOLOCK) WHERE WinlostDate = @WinlostDate
		SELECT @new_rowcount = COUNT(1) FROM bodb_N88_Archive.dbo.TpBetRecord_bk WITH (NOLOCK) WHERE WinlostDate = @WinlostDate

		IF @rowcount <> @new_rowcount
		BEGIN
			SET @Msg = 'Different rowcount between TpBetRecord & TpBetRecord_bk on ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
			RAISERROR(@Msg, 16, 1)
			RETURN
		END

		WAITFOR DELAY '00:00:00.280'

		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	-- Step 3: Update flag
	DECLARE @SValue VARCHAR(200) = CONVERT(VARCHAR(10), @tmpDate, 120)
	EXEC dbo.Task_N88_SystemSettings_Upd @SName = 'ArchiveData_Date', @SValue = @SValue

	-- Delay 2 mins for report which get old Archive Date
	WAITFOR DELAY '00:02:00'

	-- Step 4: Delete data
	SELECT @WinlostDate = MIN(WinlostDate) FROM dbo.TpBetRecord WITH (NOLOCK)
	WHILE @WinlostDate < @tmpDate
	BEGIN
		EXEC dbo.Task_N88_Archive_DeleteData @WinlostDate = @WinlostDate, @DataSource = 'TpBetRecord'

		WAITFOR DELAY '00:00:00.280'

		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	SELECT @WinlostDate = MIN(WinlostDate) FROM bodb_N88_Archive.dbo.TpBetRecord_bk WITH (NOLOCK)
	SELECT @tmpDate = DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)) -- first day of current month last year
	WHILE @WinlostDate < @tmpDate
	BEGIN
		EXEC dbo.Task_N88_Archive_DeleteData @WinlostDate = @WinlostDate, @DataSource = 'TpBetRecord_bk'

		WAITFOR DELAY '00:00:00.280'

		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	-- Step 5: Send mail if data is changed
	EXEC dbo.Task_N88_Archive_SendMail
END
GO