USE [msdb]
GO

/****** Object:  Job [Task : Replication for DBTrans.bodb02.dbo.UserLog]    Script Date: 01/16/2015 01:50:41 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/16/2015 01:50:41 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Task : Replication for DBTrans.bodb02.dbo.UserLog', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get the list]    Script Date: 01/16/2015 01:50:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get the list', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'TRUNCATE TABLE dbo.tmp_UserLog_T

-- *************************
-- *************************

Declare @current bigint
SELECT @current = MAX(logid) FROM dbo.UserLog_T with (nolock)

INSERT INTO dbo.tmp_UserLog_T (LogID, userid, doing, logdate)
SELECT TOP (11000) LogID, userid, doing, logdate
FROM DBTrans.bodb02.dbo.UserLog with (nolock)
WHERE logid > (@current - 1000)
ORDER BY logid

DELETE X
FROM dbo.tmp_UserLog_T X
INNER JOIN dbo.UserLog_T T with (nolock)
ON X.logid = T.logid

-- *************************
-- *************************

Declare @cnt int
SELECT @cnt = COUNT(*) FROM dbo.tmp_UserLog_T

IF IsNull(@cnt, 0) = 0
BEGIN
	-- raiserror here to continue to next step of jobs
	RAISERROR (''* next round *'', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [copy from DBTrans (1 by 1)]    Script Date: 01/16/2015 01:50:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'copy from DBTrans (1 by 1)', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=1, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON

Declare @maxdelay datetime
Declare @logid bigint, @rc int, @rid int, @maxrid int
Declare @userid int, @doing nvarchar(300), @logdate datetime, @extend int

SELECT @rid = MIN(rid), @maxrid = MAX(rid), @extend = 0, @rc = 0 FROM dbo.tmp_UserLog_T
SELECT @maxdelay = logdate FROM dbo.tmp_UserLog_T WHERE rid = @rid

SET IDENTITY_INSERT UserLog_T ON

LoopAgain:

SELECT @logid = logid, @userid = userid, @doing = doing, @logdate = logdate
FROM dbo.tmp_UserLog_T WHERE rid = @rid

IF @@ROWCOUNT > 0
BEGIN
	EXEC dbo.Task_UserLogExtend @string = @doing, @result = @extend OUTPUT
	
	INSERT INTO dbo.UserLog_T  (logid, userid, doing, logdate, extend)
	SELECT @logid, @userid, @doing, @logdate, @extend
END

SELECT @rid = @rid + 1, @extend = 0, @rc = @rc + 1

IF @rid <= @maxrid GOTO LoopAgain

SET IDENTITY_INSERT UserLog_T OFF 
SET NOCOUNT OFF

PRINT '' ** '' + CAST(@rc as varchar(20)) + '' rows inserted ** ''
+ '' Delay '' 
+ CAST(DATEDIFF(ms, @maxdelay, CURRENT_TIMESTAMP) as varchar(20)) + '' / ''
+ CAST(DATEDIFF(ms, @LogDate, CURRENT_TIMESTAMP) as varchar(20)) + '' ms ** ''

-- xxxxxxxxxxxxxxxxxxxxxxxxxx

IF RIGHT(CAST(@logid as varchar(50)), 6) = 0
BEGIN
	DELETE FROM dbo.tmp_Task_UserLogExtend
	WHERE vid NOT IN (
		SELECT oddsid FROM dbo.odds with (nolock)
		UNION ALL
		SELECT matchid FROM dbo.match with (nolock)
		UNION ALL
		SELECT orid FROM dbo.outright with (nolock)
		)
END

IF IsNull(@rc, 0) < 10
BEGIN
	-- raiserror here to continue to next step of jobs
	RAISERROR (''* next round *'', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [delay 5 seconds]    Script Date: 01/16/2015 01:50:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'delay 5 seconds', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=1, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'WAITFOR DELAY ''000:00:05.000''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'10 seconds', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20131025, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'4c04f15f-67d3-4d25-8e67-93b5cc2cf958'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


