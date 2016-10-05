USE [msdb]
GO

/****** Object:  Job [winlost report update (daily)]    Script Date: 10/05/2016 00:18:10 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/05/2016 00:18:10 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'winlost report update (daily)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', 
		@notify_email_operator_name=N'Viet', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Task_DailyArchiveRptDepWinlost]    Script Date: 10/05/2016 00:18:10 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Task_DailyArchiveRptDepWinlost', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[Task_DailyArchiveRptDepWinlost]
GO

DECLARE @date smalldatetime
SELECT @date = MIN(winlostdate) FROM bodb_report.dbo.rptDepWinlost WITH(nolock)

WHILE (@date < DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP)-5, 0))
BEGIN
	EXEC bodb_report.dbo.Task_DepWinlostSUM @date
	SELECT @date=dateadd(dd, 1, @date)
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SUM data]    Script Date: 10/05/2016 00:18:10 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SUM data', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @Yesterday SMALLDATETIME
    , @WinlostDate SMALLDATETIME
    , @MoveBetsDay SMALLDATETIME
    , @Temp SMALLDATETIME
    , @ThreeDaysAgo SMALLDATETIME
     
SELECT @Yesterday = DATEADD(dd, -1, CONVERT(NVARCHAR(10), CURRENT_TIMESTAMP, 120))
SELECT @ThreeDaysAgo = DATEADD(dd, -2, @Yesterday)
 
SELECT @MoveBetsDay = MAX(eventdate)
FROM dbo.match14 WITH(NOLOCK)
IF @MoveBetsDay IS NULL
    RETURN

SET @Temp = DATEADD(DAY,-1,@MoveBetsDay)

IF @ThreeDaysAgo < DATEADD(DAY,-1,@MoveBetsDay)
BEGIN
    SET @Temp = @ThreeDaysAgo
END

WHILE @Temp <= @Yesterday
BEGIN
    PRINT ''WinlostDate: '' + CONVERT(NVARCHAR(10), @Temp, 120)
    EXEC dbo.Task_DOT_Dep_DailySummary_FULL @Temp
    SET @Temp = DATEADD(dd, 1, @Temp)
END
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20081226, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'be199510-4b40-4a6b-b9dd-2d0fc013b3e1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


