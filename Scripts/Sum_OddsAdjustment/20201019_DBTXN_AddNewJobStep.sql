/*<info serverAlias="DBTXN-bodb02"></info>*/
/*
	Created: 20201019@Sol
	DB: DBTXN-bodb02
	Task: Add new job step - Step name: Daily summary odds addjustment in bettrans - [#Redmind: 142532]

*/
USE [msdb]
GO
/****** Object:  Step [Generate data]    Script Date: 10/19/2020 9:35:55 AM ******/
EXEC msdb.dbo.sp_delete_jobstep @job_name = 'bodb02: Licensee Winloss AG GD VG', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name = 'bodb02: Licensee Winloss AG GD VG', @step_name=N'Daily summary odds addjustment in bettrans', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_Dep_DailySum_OddsAdjustment_Job', 
		@database_name=N'bodb02', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name = 'bodb02: Licensee Winloss AG GD VG', @step_name=N'Generate data', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlostDate SMALLDATETIME
SELECT  @WinlostDate = CONVERT(VARCHAR(10), DATEADD(DAY, -1, GETDATE()), 112)
EXEC dbo.Task_DEP_SeparatedWallet_GenerateData @WinlostDate = @WinlostDate', 
		@database_name=N'bodb02', 
		@flags=0
GO
