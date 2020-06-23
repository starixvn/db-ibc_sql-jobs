/*<info serverAlias="DBSUM-bodb_Summary"></info>*/

/*
	Created: 20200618@Malcolm
	Task: add new steps for job [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
*/

USE msdb
GO

EXEC  msdb.dbo.sp_add_jobstep @job_name ='bodb_Summary: Generate Data - Before MoveBets', @step_name=N'Sum_Winloss_Extra', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_DailySum_Winloss_Extra_Job', 
		@database_name=N'bodb_Summary', 
		@flags=0

EXEC msdb.dbo.sp_update_jobstep 
		@job_name = N'bodb_Summary: Generate Data - Before MoveBets',  
		@step_id = 1,  
		@on_success_action = 3

EXEC  msdb.dbo.sp_add_jobstep @job_name ='bodb_Summary: Check and Correct Data - After MoveBets', @step_name=N'Sum_Winloss_Extra', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_DailySum_Winloss_Extra_CheckData_Job', 
		@database_name=N'bodb_Summary', 
		@flags=0

EXEC msdb.dbo.sp_update_jobstep 
		@job_name = N'bodb_Summary: Check and Correct Data - After MoveBets',  
		@step_id = 4,
		@on_success_action = 3

