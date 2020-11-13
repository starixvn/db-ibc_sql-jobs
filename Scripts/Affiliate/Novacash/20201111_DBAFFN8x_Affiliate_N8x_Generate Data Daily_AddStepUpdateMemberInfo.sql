/*<info serverAlias="DBAFFN88-Affiliate_N88" isFunction="0" isNested="0"></info>*/
/*
	Created: 20201111@Percy
	DB: DBAFFN88-msdb
	Task: Job - Generate Data Daily
		1. Add step Updated Member Info
		2. Re-order steps
*/
use msdb
go

-- N88
exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N88: Generate Data Daily'
	,@step_id = 3
	,@step_name = 'Import Member Data'
	,@cmdexec_success_code = 0
	,@on_success_action = 3
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ImportData_Job'
go

exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N88: Generate Data Daily'
	,@step_id = 4
	,@step_name = 'Clear user login'
	,@cmdexec_success_code = 0
	,@on_success_action = 1
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ClearLogin'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N88: Generate Data Daily'
	,@step_id = 1
	,@step_name = 'Import Exchange Oanda'
	,@command = 'EXEC dbo.Task_ExchangeOanda_Import'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N88: Generate Data Daily'
	,@step_id = 2
	,@step_name = 'Updated Member Info'
	,@on_success_action = 3
	,@command = 'EXEC dbo.Task_Aff_MemberInfo_Upd'
go

-- N8B
exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N8B: Generate Data Daily'
	,@step_id = 3
	,@step_name = 'Import Member Data'
	,@cmdexec_success_code = 0
	,@on_success_action = 3
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ImportData_Job'
go

exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N8B: Generate Data Daily'
	,@step_id = 4
	,@step_name = 'Clear user login'
	,@cmdexec_success_code = 0
	,@on_success_action = 1
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ClearLogin'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N8B: Generate Data Daily'
	,@step_id = 1
	,@step_name = 'Import Exchange Oanda'
	,@command = 'EXEC dbo.Task_ExchangeOanda_Import'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N8B: Generate Data Daily'
	,@step_id = 2
	,@step_name = 'Updated Member Info'
	,@on_success_action = 3
	,@command = 'EXEC dbo.Task_Aff_MemberInfo_Upd'
go

-- N8G
exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N8G: Generate Data Daily'
	,@step_id = 3
	,@step_name = 'Import Member Data'
	,@cmdexec_success_code = 0
	,@on_success_action = 3
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ImportData_Job'
go

exec dbo.sp_add_jobstep
	@job_name = 'Affiliate_N8G: Generate Data Daily'
	,@step_id = 4
	,@step_name = 'Clear user login'
	,@cmdexec_success_code = 0
	,@on_success_action = 1
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem=N'TSQL'
	,@command = 'EXEC dbo.Task_Aff_ClearLogin'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N8G: Generate Data Daily'
	,@step_id = 1
	,@step_name = 'Import Exchange Oanda'
	,@command = 'EXEC dbo.Task_ExchangeOanda_Import'
go

exec dbo.sp_update_jobstep
	@job_name = 'Affiliate_N8G: Generate Data Daily'
	,@step_id = 2
	,@step_name = 'Updated Member Info'
	,@on_success_action = 3
	,@command = 'EXEC dbo.Task_Aff_MemberInfo_Upd'
go