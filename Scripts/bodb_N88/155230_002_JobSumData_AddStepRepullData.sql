/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210524@Percy
	DB: DBN88-bodb_N88
	Task: Add step daily re-pull data
*/

USE msdb
GO

EXEC msdb.dbo.sp_add_jobstep
	@job_name='bodb_N88: Generate daily data for N88_RptWinloss',
	@step_name=N'Auto repull data',
	@step_id=2,
	@cmdexec_success_code=0,
	@on_success_action=3,
	@on_success_step_id=0,
	@on_fail_action=2,
	@on_fail_step_id=0,
	@retry_attempts=0,
	@retry_interval=0,
	@os_run_priority=0,
	@subsystem=N'TSQL',
	@command=N'EXEC Task_N88_RepullData',
	@database_name=N'bodb_N88',
	@flags=0