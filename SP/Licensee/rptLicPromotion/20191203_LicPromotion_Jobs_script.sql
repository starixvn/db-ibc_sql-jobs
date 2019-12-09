/*
	Created: 20191203@Bobby
	Task: Summarize Promotion data into rptLicPromotion [Redmine: #119538]
	DB: DBLIC.bodb_LicenseeReport
*/
use msdb
GO

DECLARE @ReturnCode INT
DECLARE @job_name nvarchar(200) = N'bodb_LicenseeReport: DW - Generate Daily'
SELECT @ReturnCode = 0

/****** Object:  Step [Generate RptPromotion - Summany]    Script Date: 12/4/2019 1:07:25 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=@job_name, @step_name=N'Generate RptPromotion - Summany', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[Task_DailySummaryLicPromotion_Job]', 

		@database_name=N'bodb_LicenseeReport', 
		@flags=0

SELECT @ReturnCode AS [@ReturnCode]
GO