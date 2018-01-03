USE [msdb]
GO

/****** Object:  Job [bodb02: Licensee Winloss AG GD VG]    Script Date: 1/3/2018 10:49:19 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/3/2018 10:49:20 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02: Licensee Winloss AG GD VG', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check data ready or not]    Script Date: 1/3/2018 10:49:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check data ready or not', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON
DECLARE @WinlostDate SMALLDATETIME
    , @LimitTime VARCHAR(8)
    , @CurrentTime TIME
    , @IsReady BIT
    , @ErrrMessage VARCHAR(100)

SELECT GETDATE()
SELECT @WinlostDate = CONVERT(VARCHAR(10), DATEADD(dd, -1, GETDATE()), 112)
    , @CurrentTime = CONVERT(VARCHAR(8), GETDATE(), 114)
    , @LimitTime = ''03:00:00''

IF EXISTS (SELECT 1
				FROM bodb02.dbo.bettrans WITH(NOLOCK)
				WHERE winlostdate = @WinlostDate AND bettype IN (1700, 1800, 1900, 8000))
BEGIN
    SET @ErrrMessage = ''* already generated data for winlostdate: '' + CONVERT(VARCHAR(10), @WinlostDate, 112) + '' *''
    RAISERROR (@ErrrMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
END

WHILE @CurrentTime < @LimitTime
BEGIN
    
    EXEC DBLIC.bodb_licensee.dbo.Task_DEP_SeparatedWallet_Data_Check @WinlostDate = @WinlostDate
	   , @IsReady = @IsReady OUTPUT

    IF @IsReady = 1
    BEGIN
	   BREAK
    END
    ELSE
    BEGIN
	   SET @ErrrMessage = ''* data not ready yet for winlostdate: '' + CONVERT(VARCHAR(10), @WinlostDate, 112) + '' *''
	   RAISERROR(@ErrrMessage, 0, 0) WITH NOWAIT
    END

    WAITFOR DELAY ''00:10:00''
    SELECT @CurrentTime = CONVERT(VARCHAR(8), GETDATE(), 114)
END
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step - Sum data daily @dbdb02]    Script Date: 1/3/2018 10:49:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step - Sum data daily @dbdb02', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlostDate SMALLDATETIME
SET @WinlostDate = CONVERT(VARCHAR(12), GETDATE() - 1, 112)
EXEC dbo.Task_Dep_DailySumData3rdProduct @WinlostDate = @WinlostDate', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step - Adjust data @bodb02]    Script Date: 1/3/2018 10:49:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step - Adjust data @bodb02', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WinlostDate SMALLDATETIME
SET @WinlostDate = CONVERT(VARCHAR(12), GETDATE() - 1, 112)
EXEC dbo.Task_Dep_AdjustData3rdProduct @WinlostDate = @WinlostDate
	, @DayForAdjustment  = ''1,2,3,4,5,6,7''', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150605, 
		@active_end_date=99991231, 
		@active_start_time=1500, 
		@active_end_time=235959, 
		@schedule_uid=N'1c4879de-579c-4ac5-9fe1-b93ce7a0febd'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


