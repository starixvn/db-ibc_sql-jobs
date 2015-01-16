USE [msdb]
GO

/****** Object:  Job [load UserLog]    Script Date: 01/15/2015 22:53:35 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/15/2015 22:53:35 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'load UserLog', 
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
/****** Object:  Step [load log]    Script Date: 01/15/2015 22:53:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'load log', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET DEADLOCK_PRIORITY LOW
SET IDENTITY_INSERT UserLog_T ON

declare @mid bigint
declare @a int, @b int

select @mid = max(logid) from userlog_T (nolock)

INSERT INTO UserLog_T (logid, userid, doing, logdate, extend)
SELECT logid, userid, doing, logdate, 0
FROM DBTrans.bodb02.dbo.UserLog with (nolock)
WHERE logid BETWEEN @mid + 1 AND @mid + 150
AND doing LIKE ''Customer%''
SET @a = @@ROWCOUNT

INSERT INTO UserLog_T (logid, userid, doing, logdate, extend)
SELECT logid, userid, doing, logdate, dbo.f_MatchLog(doing)
FROM DBTrans.bodb02.dbo.UserLog with (nolock)
WHERE logid BETWEEN @mid + 5 AND @mid + 150
AND doing NOT LIKE ''Customer%''
SET @b = @@ROWCOUNT


PRINT '' ** Total '' + CAST(@a as nvarchar(10)) + '' : '' + CAST(@b as nvarchar(10)) + '' ** ''', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check loop]    Script Date: 01/15/2015 22:53:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check loop', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=1, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
Declare @mid bigint
SELECT @mid = MAX(logid) FROM UserLog_T with (nolock)

IF @mid > 4847118586
BEGIN
	-- raiserror here to continue to next step of jobs
	RAISERROR (''* no more data *'', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END

WAITFOR DELAY ''000:00:00.300''
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


