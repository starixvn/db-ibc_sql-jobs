/*<info serverAlias="DBTXN-msdb" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:20221003@Louisa
   Task: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#178231]
 
	DB: DBTXN/msdb
 	
	Revisions:
		- 20221003@Louisa: Add Job check Balance Pending process is slowly [Redmine:#178231]
 	
	Param's Explanation: 
 
*/

USE [msdb]
GO


BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category 
			@class=N'JOB', 
			@type=N'LOCAL', 
			@name=N'[Uncategorized (Local)]'
		
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
	END


	IF EXISTS ( SELECT TOP 1 1 FROM sysjobs j WHERE  j.name = N'vndba:Check slowly BalanceUpdCreditSports process' )
	BEGIN
		EXEC @ReturnCode =  msdb.dbo.sp_delete_job  @job_name = N'vndba:Check slowly BalanceUpdCreditSports process'
		
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job 
			@job_name=N'vndba:Check slowly BalanceUpdCreditSports process', 
			@enabled=0, 
			@description=N'', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa',
			@job_id = @jobId OUTPUT
	
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback
		
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver 
		@job_id = @jobId, 
		@server_name = N'(local)'

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback


	IF NOT EXISTS ( SELECT TOP 1 1 FROM sysjobsteps js
					INNER JOIN sysjobs j
					ON j.job_id = js.job_id
					WHERE j.name = N'vndba:Check slowly BalanceUpdCreditSports process'
						AND js.step_name = N'Check slowly BalanceUpdCreditSports process'
					)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				@job_id=@jobId, 
				@step_name=N'Check slowly BalanceUpdCreditSports process', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=4, --go to next step
				@on_success_step_id=2,
				@on_fail_action=2, --quit job
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'EXEC dbo.Task_Check_LongRunning_BalanceUpdCreditSports', 
				@database_name=N'bodb02', 
				@flags=0
	
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
		
	END

	IF NOT EXISTS ( SELECT TOP 1 1 FROM sysjobsteps js
					INNER JOIN sysjobs j
					ON j.job_id = js.job_id
					WHERE j.name = N'vndba:Check slowly BalanceUpdCreditSports process'
						AND js.step_name = N'Waitfor delay 180ms'
					)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				@job_id=@jobId, 
				@step_name=N'Waitfor delay 180ms', 
				@step_id=2, 
				@cmdexec_success_code=0, 
				@on_success_action=4, --go to next step
				@on_success_step_id=1, --go back to step 1
				@on_fail_action=2,  --quit job
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'WAITFOR DELAY ''00:00:00.180''', 
				@database_name=N'bodb02', 
				@flags=0
	
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
	END

	EXEC @ReturnCode = msdb.dbo.sp_update_job 
		@job_id = @jobId, 
		@start_step_id = 1
	
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION

EndSave:
GO


