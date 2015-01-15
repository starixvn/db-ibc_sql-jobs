USE [msdb]
GO

/****** Object:  Job [Aff's Member daily update]    Script Date: 01/08/2015 03:41:51 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/08/2015 03:41:51 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Aff''s Member daily update', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', 
		@notify_email_operator_name=N'Viet', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Call Job]    Script Date: 01/08/2015 03:41:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Call Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @Today smalldatetime, @Hour int
SELECT @Today = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)
SELECT @Hour = DATEPART(hour, CURRENT_TIMESTAMP)

EXEC Task_Aff_DailySummaryClickRate_New

IF (@Hour between 16 and 18) -- 3AM-5AM (VN time) Calculate all data in bettrans and bettrans14 
BEGIN
	DECLARE @balanceupday SMALLDATETIME, @tmp SMALLDATETIME

	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.Bettrans WITH(NOLOCK)  
	WHERE bettype = 20000 and matchid = 0 and custid = 3

	SELECT @tmp = dateadd(dd, 1, @balanceupday)
	WHILE (@tmp <= @today)
	BEGIN
		SELECT @tmp	
		EXEC dbo.Task_Aff_MemberDailySummary @tmp				
		SELECT @tmp = dateadd(dd, 1, @tmp)
		WAITFOR DELAY ''00:00:06''
	END
END
ELSE

BEGIN
	Declare @Yesterday smalldatetime, @Earlyday smalldatetime

	SELECT @Yesterday = DATEADD(day, -1, @Today), @Earlyday = DATEADD(day, -2, @Today)

	EXEC dbo.Task_Aff_MemberDailySummary @Today
	EXEC dbo.Task_Aff_MemberDailySummary @Yesterday
	EXEC dbo.Task_Aff_MemberDailySummary @Earlyday	
END

EXEC dbo.Task_Aff_CustomerInsMember', 
		@database_name=N'Affiliate_12BET', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [delete old bettransDep data]    Script Date: 01/08/2015 03:41:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'delete old bettransDep data', 
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
declare @date smalldatetime
set @date = CONVERT(varchar(10), current_timestamp, 120)
set @date = DATEADD(dd, -1, @date)

--DELETE dbo.bettransDEP WHERE winlostdate < @date
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'aff''s member daily update', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20090721, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959, 
		@schedule_uid=N'd2765b6a-0543-4659-8728-02def94173f9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


