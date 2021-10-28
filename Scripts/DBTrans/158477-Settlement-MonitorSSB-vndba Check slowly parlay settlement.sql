/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
USE [msdb]
GO

/*  Created: Kathy@20211028
	Task: Write logs
	DB: DBTXN-bodb02
	Revisions:  
		- 20211028@Kathy: Monitor SSB status [Redmine:#159486]
*/
EXEC msdb.dbo.sp_add_jobstep @job_name=N'vndba:Check slowly parlay settlement', @step_name=N'Check SSB Status', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.SSB_Settlement_MonitorLogs @MonitorDurationWithInMin = 120', 
		@database_name=N'bodb02', 
		@flags=0

		GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'vndba:Check slowly parlay settlement', @step_name=N'Check Balance Error', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_Settlement_LongRunning_Check @Step = 5', 
		@database_name=N'bodb02', 
		@flags=0



