/*<info serverAlias="DBAGE-bodb02" executers="" selectors="" viewers="" isFunction="0" isNested="0"></info>*/
/* 
	Created by:20231025@Lewis
    Task: Support to cross check duplicated data caused by different sum jobs [Redmine:#193254]
    DB: DBAGE/bodb02

*/

USE [msdb]
GO
EXEC sp_add_jobstep  
    @job_name = N'bodb_Summary: Check and Correct Data - After MoveBets',  
    @step_name = N'Check Data Sum_Winloss vs Bettrans14',  
	@step_id= 6,
	@cmdexec_success_code = 0,
	@on_success_action = 1,
	@on_success_step_id = 0,
	@on_fail_action = 2,
	@on_fail_step_id = 0,
	@retry_attempts = 0,
	@retry_interval = 0,
	@os_run_priority = 0,
	@subsystem = N'TSQL',  
    @command = N'EXEC Task_Sum_Winloss_CheckData_Job',
	@database_name  =N'bodb02',
	@flags = 0
GO

EXEC msdb.dbo.sp_update_jobstep 
		@job_name = N'bodb_Summary: Check and Correct Data - After MoveBets',  
		@step_id = 5,
		@on_success_action = 3
GO

