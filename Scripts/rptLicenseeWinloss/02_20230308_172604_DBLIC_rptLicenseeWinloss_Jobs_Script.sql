/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - Add Job steps
	DB: DBLIC.msdb
	Remark: Run on pair DB052-DB053
*/

use msdb;
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT, @job_name nvarchar(128);

SELECT @ReturnCode = 0,
		@job_name = N'bodb_LicenseeReport: Daily Summary Licensee Winloss'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=@job_name, 
		@step_name=N'Gen Data for @ rptLicenseeWinloss', 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=5, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_DailyRptLicWinloss2_Job @TableName = ''rptLicenseeWinloss''', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_name=@job_name,
		@step_id=10, 
		@on_success_action=3
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
------------------------------------------------------------

SELECT @ReturnCode = 0,
		@job_name = N'bodb_LicenseeReport: Licensee Winloss - Check and Correct Data'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=@job_name, 
		@step_name=N'Check and Correct Data for @ rptLicenseeWinloss', 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=5, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_DailyRptLicWinloss2_CheckData_Job @TableName = ''rptLicenseeWinloss''', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_name=@job_name,
		@step_id=12, 
		@on_success_action=3
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO