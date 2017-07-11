USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb_LicenseeReport: DW - Generate Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Process data daily', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Readiness]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Readiness', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=12, 
		@retry_interval=10, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_DW_CheckReadiness', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Process staging data]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Process staging data', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=4, 
		@on_fail_action=4, 
		@on_fail_step_id=1, 
		@retry_attempts=3, 
		@retry_interval=15, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_PrepareStaging', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [GEN report 3rd Product]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'GEN report 3rd Product', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlossDate DATE
SET @WinlossDate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
EXEC dbo.Task_DOT_3rd_DailySummary @WinlostDate = @WinlossDate', 
		@database_name=N'bodb_3rdProduct', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Customer Account]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate Customer Account', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.GEN_Customer_Account2', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Betting]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate Betting', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.GEN_Betting', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate KPI]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate KPI', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=12, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.GEN_rptKPIReports', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate rpt_BettingByProduct @ bodb_licenseeReport]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate rpt_BettingByProduct @ bodb_licenseeReport', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @fromDate datetime, @toDate datetime
SELECT @fromDate = min(winlostdate) FROM bodb02.dbo.bettrans14 (NOLOCK)
SET @toDate = DATEADD(DAY,-1,CONVERT(VARCHAR(10),GETDATE(),120))

EXEC dbo.GEN_rptBettingByProduct @fromDate, @toDate', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Gen data for Active Customer Report @bodb_LicenseeReport]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Gen data for Active Customer Report @bodb_LicenseeReport', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @TransDate DATE
SET @TransDate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
EXEC dbo.Task_CustomerActive_GenDataDaily @TransDate = @TransDate', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Gen data for Keno winloss Report @bodb_LicenseeReport]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Gen data for Keno winloss Report @bodb_LicenseeReport', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlossDate DATE, @BF_EarlyDay DATE
SET @WinlossDate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
SET @BF_EarlyDay = DATEADD(DAY, -2, @WinlossDate)
WHILE @WinlossDate >= @BF_EarlyDay
BEGIN
	EXEC dbo.Task_KenoWinloss_GenDataFromBettrans @WinlossDate = @WinlossDate
	SET @WinlossDate = DATEADD(DAY, -1, @WinlossDate)		
END', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Gen data for Microgaming Casino Report @bodb_LicenseeReport]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Gen data for Microgaming Casino Report @bodb_LicenseeReport', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlossDate DATE, @BF_EarlyDay DATE
SET @WinlossDate = DATEADD(DAY, -1, CONVERT(VARCHAR(10), GETDATE(), 120))
SET @BF_EarlyDay = DATEADD(DAY, -2, @WinlossDate)
WHILE @WinlossDate >= @BF_EarlyDay
BEGIN
	EXEC dbo.Task_Microgaming_Bettrans @WinlossDate = @WinlossDate
	SET @WinlossDate = DATEADD(DAY, -1, @WinlossDate)		
END', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate rpt_BettingBySport @ bodb_LicenseeReport]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate rpt_BettingBySport @ bodb_LicenseeReport', 
		@step_id=11, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @FromDate smalldatetime, @ToDate smalldatetime

select @FromDate = min(b.winlostdate), @ToDate = max(b.winlostdate)
from dbo.bettrans b with(nolock)

exec bodb_LicenseeReport.dbo.GEN_rptBettingBySport @FromDate = @FromDate, 
		               @ToDate = @ToDate', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [POST staging :)]    Script Date: 3/9/2017 5:32:34 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'POST staging :)', 
		@step_id=12, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_PostStaging', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'End of business day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110623, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, 
		@schedule_uid=N'7e0fef12-a6ec-446a-84f4-a8505827bd6c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


