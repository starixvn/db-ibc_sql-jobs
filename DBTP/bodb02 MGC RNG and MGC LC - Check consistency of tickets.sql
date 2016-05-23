USE [msdb]
GO

/****** Object:  Job [bodb02: MGC RNG and MGC LC - Check consistency of tickets]    Script Date: 5/23/2016 9:49:15 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 5/23/2016 9:49:15 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02: MGC RNG and MGC LC - Check consistency of tickets', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'dbateam', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check consistency of tickets]    Script Date: 5/23/2016 9:49:15 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check consistency of tickets', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @Fromdate smalldatetime, @Todate smalldatetime, @ErrMessage varchar(1024), @ErrorTmp varchar(1024)

select @Todate = getdate()
select @Fromdate = dateadd(day, -2, @Todate)

select @ErrorTmp = '', @ErrMessage = ''

exec dbo.Task_RNG_Check_Data_Consistency_Job @FromDate = @Fromdate
	, @ToDate = @Todate
	, @ErrMessage = @ErrorTmp OUTPUT

if isnull(@ErrorTmp, '') <> ''
	set @ErrMessage = @ErrMessage + @ErrorTmp

set @ErrorTmp = ''
exec dbo.Task_MicroGamingLC_DataConsistency_Check @FDate = @Fromdate
	, @TDate = @Todate
	, @ErrMessage =  @ErrorTmp OUTPUT

if isnull(@ErrorTmp, '') <> ''
	set @ErrMessage = @ErrMessage + @ErrorTmp

if isnull(@ErrMessage, '') <> ''
	raiserror(@ErrMessage, 16, 1)', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sche: Every day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121007, 
		@active_end_date=99991231, 
		@active_start_time=500, 
		@active_end_time=235959, 
		@schedule_uid=N'ed6902ab-2ace-442f-a686-e0bd6c82f6ac'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


