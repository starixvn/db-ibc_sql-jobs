/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBLIC-msdb
	Task: New table rpt_CustomerWL_ExtraGMT
	RedmineID: #134867 - Calculating pay to supplier for some special customers

	Step 4: Add SP gen data into job
*/
USE [msdb]
GO

EXEC sp_update_jobstep
	@job_name=N'bodb_LicenseeReport: DW - Generate Daily',
	@step_id=6,
	@command=N'DECLARE @WinlossDate DATE, @BF_EarlyDay DATE
SET @WinlossDate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
SET @BF_EarlyDay = DATEADD(DAY, -2, @WinlossDate)
WHILE @WinlossDate >= @BF_EarlyDay
BEGIN
	EXEC dbo.Task_Microgaming_Bettrans @WinlossDate = @WinlossDate

	EXEC dbo.Task_rpt_CustomerWL_ExtraGMT @WinlostDate = @WinlossDate

	SET @WinlossDate = DATEADD(DAY, -1, @WinlossDate)
END'