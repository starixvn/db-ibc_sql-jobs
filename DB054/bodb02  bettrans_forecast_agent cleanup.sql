USE [msdb]
GO

/****** Object:  Job [bodb02 : bettrans_forecast_agent cleanup]    Script Date: 01/14/2015 23:45:34 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/14/2015 23:45:34 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : bettrans_forecast_agent cleanup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [delete forecast of Completed event]    Script Date: 01/14/2015 23:45:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'delete forecast of Completed event', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--SET DEADLOCK_PRIORITY LOW

-- get list
SELECT DISTINCT matchid
INTO #bfa
FROM dbo.bettrans_forecast_agent with (nolock)

-- remove unfinish event
-- only Finished event will left here  OR some event without link
DELETE B
FROM #bfa B INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid AND m.eventstatus <> ''Completed''

Declare @match TABLE (rn int PRIMARY KEY IDENTITY(1,1), matchid int)
INSERT INTO @match (matchid)
SELECT matchid FROM #bfa

IF @@ROWCOUNT > 0
BEGIN
	Declare @rn int, @xrn int, @matchid int
	SET @rn = 1
	SET @xrn = (SELECT max(rn) FROM @match)

	WHILE @rn <= @xrn
	BEGIN
		SELECT @matchid = matchid FROM @match WHERE rn = @rn

		delete from dbo.bettrans_forecast_agent
		WHERE matchid = @matchid

		SET @rn = @rn + 1
	END
END
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'20 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110928, 
		@active_end_date=99991231, 
		@active_start_time=45, 
		@active_end_time=235959, 
		@schedule_uid=N'c35d19e5-7169-4e9b-bb61-057f901cc9cc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


