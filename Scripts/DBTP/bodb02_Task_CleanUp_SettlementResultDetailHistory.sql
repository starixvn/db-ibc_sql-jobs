/*<info serverAlias="DBTP-msdb" executers="" selectors="" viewers="" isFunction="0" isNested="0"></info>*/
/* 
	Created:20220324@Louisa
    Task: Trigger on ResultDetail/OS/ES [Redmine:#170548]
    DB: DBTP/msdb
	
	Revisions:
		- 20220324@Louisa: Cleanup History data for trigger on table ResultDetail/OS/ES [Redmine:#170548]
*/
USE [msdb]
GO

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	DECLARE @jobId BINARY(16)

	SELECT @ReturnCode = 0

	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : Task_CleanUp_SettlementResultDetailHistory', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0,  
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Task_CleanUp_SettlementResultDetailHistory', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'EXEC NAP_Set_CleanUp_SettlementResultDetailHistory_Job', 
			@database_name=N'bodb02', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


