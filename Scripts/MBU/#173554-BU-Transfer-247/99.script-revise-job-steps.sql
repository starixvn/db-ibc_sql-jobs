/*<info serverAlias="DBTXN-bodb02"></info>*/
exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 1
	, @command = N'EXEC dbo.Task_BalanceUp_CalculateBalanceUpDate'
	, @step_name = N'Calculate new balanceUp date'
	
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 2
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 1'
	, @step_name = N'Turn on 20k flag'
	
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 3
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 2'
	, @step_name = N'Data verification'
	
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 4
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 3'
	, @step_name = N'Backup databases'
	
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 5
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 4'
	, @step_name = N'Calculate balance'
	
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 6
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 5'
	, @step_name = N'Insert new 20k'
	
go

--add new step
exec msdb.dbo.sp_add_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 7
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 6'
	, @step_name = N'Wait others server done insert 20k'
	, @database_name = 'bodb02'
	, @on_success_action = 3
	
go

--add new step
exec msdb.dbo.sp_add_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 8
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 7'
	, @step_name = N'Delete old data'
	, @database_name = 'bodb02'
	, @on_success_action = 3
go

exec msdb.dbo.sp_update_jobstep @job_name = N'DBTRANS : Balance Up (Background)'
	, @step_id = 9
	, @command = N'EXEC dbo.Task_BalanceUp_background @step = 8'
	, @step_name = N'Finishing'
	
go