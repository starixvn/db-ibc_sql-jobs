/*<info serverAlias="DBCTG-msdb,DBSIC-msdb"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance - Check long running
	DB: DBCTG-msdb,DBSIC-msdb
	Remark: Run on credit site only
*/

use msdb;
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT, @job_name nvarchar(128);

SELECT @ReturnCode = 0,
		@job_name = N'vndba:Check slowly running or failed processes'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=@job_name, 
		@step_name=N'Alpha - AutoJob ClearBalance check long running', 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=5, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Age_ClearBalanceCust_Job_Monitor', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_name=@job_name,
		@step_id=9, 
		@on_success_action=3
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
