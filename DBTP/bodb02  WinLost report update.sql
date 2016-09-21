USE [msdb]
GO

/****** Object:  Job [bodb02 : WinLost report update]    Script Date: 09/15/2016 07:04:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/15/2016 07:04:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : WinLost report update', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', 
		@notify_email_operator_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cal Job : Task_rptWinLost_UpdateTable]    Script Date: 09/15/2016 07:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cal Job : Task_rptWinLost_UpdateTable', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=4, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @Hour int
Declare @Today smalldatetime
Declare @Yesterday smalldatetime
Declare @Earlyday smalldatetime

SELECT
	@Hour = DATEPART(hour, CURRENT_TIMESTAMP),
	@Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120),
	@Yesterday = DATEADD(day, -1, @Today),
	@Earlyday = DATEADD(day, -2, @Today)


--select @hour , @today, @yesterday

IF @Hour < 9
BEGIN
	EXEC dbo.Task_rptWinLost_UpdateTable @Today
	EXEC dbo.Task_rptWinLost_UpdateTable @Yesterday
	EXEC dbo.Task_rptWinLost_UpdateTable @Earlyday

END
ELSE
BEGIN
	EXEC dbo.Task_rptWinLost_UpdateTable @Today
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cal Job : Task_DOT_Dep_DailySummary_FULL]    Script Date: 09/15/2016 07:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cal Job : Task_DOT_Dep_DailySummary_FULL', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @ispermit bit
EXEC bodb02.dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT
IF @ispermit = 0 RETURN
---------

Declare @Hour int
Declare @Today smalldatetime
Declare @Yesterday smalldatetime
Declare @Earlyday smalldatetime

SELECT
	@Hour = DATEPART(hour, CURRENT_TIMESTAMP),
	@Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120),
	@Yesterday = DATEADD(day, -1, @Today),
	@Earlyday = DATEADD(day, -2, @Today)


--select @hour , @today, @yesterday

IF @Hour < 9
BEGIN	
	EXEC dbo.Task_DOT_Dep_DailySummary_FULL @Earlyday
	EXEC dbo.Task_DOT_Dep_DailySummary_FULL @Yesterday
	EXEC dbo.Task_DOT_Dep_DailySummary_FULL @Today
END
ELSE
BEGIN
	EXEC dbo.Task_DOT_Dep_DailySummary_FULL @Today	
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cal Job : Check data on rptDepWinlost and rptDepWinlostByProduct]    Script Date: 09/15/2016 07:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cal Job : Check data on rptDepWinlost and rptDepWinlostByProduct', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME
DECLARE @NumberOfDays INT
SELECT @FromDate = MIN(winlostdate) FROM bodb_Report.dbo.rptDepWinlost WITH(NOLOCK)
SELECT @ToDate = CONVERT(VARCHAR(10), GETDATE(), 120)
 
/* rptDepWinlost */
SELECT @NumberOfDays = COUNT(*)
FROM (
        SELECT winlostdate
        FROM bodb_Report.dbo.rptDepWinlost WITH(NOLOCK)
        WHERE winlostdate BETWEEN @FromDate AND @ToDate
        GROUP BY winlostdate
    )tmp
 
PRINT ''rptDepWinlost - Check on data from '' + CONVERT(VARCHAR(10), @FromDate, 120) + '' to '' + CONVERT(VARCHAR(10), @ToDate, 120)
IF ( @NumberOfDays != (DATEDIFF(DAY, @FromDate, @ToDate) + 1) )
BEGIN
    RAISERROR(''Please have a check on rptDepWinlost immediately due to some days without data'',16,1)
END
 
/* rptDepWinlostByProduct */
SELECT @NumberOfDays = COUNT(*)
FROM (
        SELECT winlostdate
        FROM bodb_Report.dbo.rptDepWinlostByProduct WITH(NOLOCK)
        WHERE winlostdate BETWEEN @FromDate AND @ToDate
        GROUP BY winlostdate
    )tmp
 
PRINT ''rptDepWinlostByProduct - Check on data from '' + CONVERT(VARCHAR(10), @FromDate, 120) + '' to '' + CONVERT(VARCHAR(10), @ToDate, 120)
IF ( @NumberOfDays != (DATEDIFF(DAY, @FromDate, @ToDate) + 1) )
BEGIN
    RAISERROR(''Please have a check on rptDepWinlostByProduct immediately due to some days without data'',16,1)
END', 
		@database_name=N'bodb_Report', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cal Job : Task_Aff_MemberDailySummary_IA]    Script Date: 09/15/2016 07:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cal Job : Task_Aff_MemberDailySummary_IA', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @Hour int
Declare @Today smalldatetime
Declare @Yesterday smalldatetime
Declare @Earlyday smalldatetime

SELECT
	@Hour = DATEPART(hour, CURRENT_TIMESTAMP),
	@Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120),
	@Yesterday = DATEADD(day, -1, @Today),
	@Earlyday = DATEADD(day, -2, @Today)


--select @hour , @today, @yesterday

IF @Hour < 9
BEGIN
	EXEC Task_Aff_MemberDailySummary_IA @Today
	EXEC Task_Aff_MemberDailySummary_IA @Yesterday
	EXEC Task_Aff_MemberDailySummary_IA @Earlyday
END
ELSE
BEGIN
	EXEC Task_Aff_MemberDailySummary_IA @Today
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 2 Hours', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070130, 
		@active_end_date=99991231, 
		@active_start_time=3030, 
		@active_end_time=235959, 
		@schedule_uid=N'bb2fd07b-9c42-4a4a-a97c-9d6fc10e43d9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


