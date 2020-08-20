/*<info serverAlias="DBLIC-bodb_3rdProduct"></info>*/

/*
	Created: 20200818@Percy
	DB: SITDB052.msdb
	Task: Job to import 3rd Product - Exchange
*/

USE [msdb]
GO

EXEC dbo.sp_add_job
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@enabled=1
	,@owner_login_name=N'sa'

EXEC dbo.sp_add_jobstep
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@step_name=N'Exchange'
	,@step_id=1
	,@cmdexec_success_code=0
	,@on_success_action=1
	,@on_success_step_id=0
	,@on_fail_action=2
	,@on_fail_step_id=0
	,@retry_attempts=0
	,@retry_interval=0
	,@os_run_priority=0
	,@subsystem=N'TSQL'
	,@command=N'DECLARE @winlostdate DATETIME
SET @winlostdate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
EXEC Task_DOT_Exchange_DailySummary @winlostdate = @winlostdate'
	,@database_name=N'bodb_3rdProduct'
	,@flags=0

EXEC dbo.sp_update_job
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@start_step_id = 1

EXEC dbo.sp_add_jobschedule
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@name=N'3 AM'
	,@enabled=1
	,@freq_type=4
	,@freq_interval=1
	,@freq_subday_type=1
	,@freq_subday_interval=0
	,@freq_relative_interval=0
	,@freq_recurrence_factor=0
	,@active_start_date=20200819
	,@active_end_date=99991231
	,@active_start_time=30000
	,@active_end_time=235959

EXEC dbo.sp_add_jobschedule
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@name=N'8 PM'
	,@enabled=1
	,@freq_type=4
	,@freq_interval=1
	,@freq_subday_type=1
	,@freq_subday_interval=0
	,@freq_relative_interval=0
	,@freq_recurrence_factor=0
	,@active_start_date=20200819
	,@active_end_date=99991231
	,@active_start_time=200000
	,@active_end_time=235959

EXEC dbo.sp_add_jobserver
	@job_name=N'bodb_3rdProduct: Generate Data'
	,@server_name = N'(local)'