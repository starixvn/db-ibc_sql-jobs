/*
	Creator:bobby@20200331
	Task: Add @add_step_id = 4 into cuurent job - [Redmine: #131490]
	DB:DB06-DB061/bodb_report
*/
use msdb;
go

declare @job_name	sysname
	,@add_step_id		int
	,@update_step_id	int
	,@step_name		sysname

SELECT @job_name = 'bodb02: Check and Correct Data - After MBU'
	, @add_step_id = 4
	, @update_step_id = 3
	, @step_name = 'Check balance consistency'

	-- Add new step
exec sp_add_jobstep @job_name = @job_name
	,@step_id = @add_step_id
	,@step_name = @step_name
	,@database_name = 'bodb_report'
	,@subsystem = N'TSQL'
	,@command = N'EXEC [dbo].[Task_DailyRptStatement_CheckBalance]'
	,@on_success_action = 1 --> quit report success
	,@on_fail_action = 2 --> quit report failure

-- Update previous step
exec sp_update_jobstep @job_name = @job_name
	,@step_id = @update_step_id
	,@on_success_action = 4 --> next action
	,@on_success_step_id = @add_step_id --> next step with id


