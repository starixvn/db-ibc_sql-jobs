/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="" viewers="" isFunction="0"></info>*/
USE msdb
GO


EXEC msdb.dbo.sp_add_jobstep @job_name=N'bodb02: TOControl Delete old transition', @step_name=N'Delete WLMonitored_AccumulatedWL (mymonitoraccount)', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3,
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=1, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Acc_WLMonitored_Service_AccumulatedDataDel', 
		@database_name=N'bodb02', 
		@flags=0

