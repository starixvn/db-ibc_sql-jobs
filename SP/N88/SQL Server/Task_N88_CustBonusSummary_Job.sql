/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_CustBonusSummary_Job]
AS

/*
	Created: 20220412@Percy
	DB: DBN88-bodb_N88
	Task: Job - Import data for CustBonusSummary

	Revisions:
		- 20220412@Percy: Initialize SP [RedmineID: #171245]
*/

BEGIN
	SET NOCOUNT ON

	-- Keep history import data within 2 days
	DECLARE @Date DATE = DATEADD(DAY, -2, GETDATE())
	DELETE dbo.BonusImportStatus WITH (ROWLOCK) WHERE Status = 'Completed' AND CheckinTime < @Date

	-- Start Import data
	UPDATE dbo.BonusImportStatus WITH (ROWLOCK) SET Status = 'running' WHERE Status = 'waiting'

	CREATE TABLE #BonusData (WinlostDate DATE, DataSource VARCHAR(128), PRIMARY KEY (WinlostDate, DataSource))
	INSERT INTO #BonusData (WinlostDate, DataSource)
	SELECT DISTINCT WinlostDate, DataSource FROM dbo.BonusImportStatus WITH (NOLOCK) WHERE Status = 'running'

	DECLARE @MinDate DATE, @MaxDate DATE, @WinlostDate DATE, @DataSources VARCHAR(4000)
	SELECT  @MinDate = MIN(WinlostDate), @MaxDate = MAX(WinlostDate) FROM #BonusData

	SET @WinlostDate = @MinDate
	WHILE @WinlostDate <= @MaxDate
	BEGIN
		SET @DataSources = NULL
		SELECT @WinlostDate = WinlostDate, @DataSources = COALESCE(@DataSources + ',', '') + DataSource FROM #BonusData WHERE WinlostDate = @WinlostDate

		IF ISNULL(@DataSources, '') <> ''
			EXEC dbo.Task_N88_CustBonusSummary @WinlostDate = @WinlostDate, @DataSources = @DataSources

		SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
	END

	UPDATE b WITH (ROWLOCK)
	SET b.Status = 'Completed', b.FinishedTime = GETDATE()
	FROM dbo.BonusImportStatus b
		INNER JOIN #BonusData t ON b.WinlostDate = t.WinlostDate AND b.DataSource = t.DataSource
	WHERE b.Status = 'running'
	
	DROP TABLE #BonusData
END
GO