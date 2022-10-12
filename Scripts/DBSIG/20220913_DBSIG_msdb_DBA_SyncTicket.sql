/*<info serverAlias="DBSIG-msdb"></info>*/
USE [msdb]
GO

/****** Object:  Job [DBA: SiteDB_bodb02 - CheckSyncTicket]    Script Date: 9/14/2022 3:47:15 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/14/2022 3:47:15 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA: SiteDB_bodb02 - CheckSyncTicket', 
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
/****** Object:  Step [Check and Sync Bet Ticket]    Script Date: 9/14/2022 3:47:15 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check and Sync Bet Ticket', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Days TABLE (ScheduleId int , Winlostdate SMALLDATETIME)

insert into @Days(ScheduleId, Winlostdate)
EXEC DBCTG.bodb02.[dbo].[Task_MoveBetsDayByScheduleSel]

declare @runningDate SMALLDATETIME, @runningIdx INT;

select @runningIdx = MIN(ScheduleId) from @Days;
while exists (select 1 from @Days where ScheduleId = @runningIdx)
begin
	select @runningDate = Winlostdate
	from @days
	where ScheduleId = @runningIdx;

	select @runningDate AS [@runningDate]
	--step 1: check movement
	EXEC [dbo].[Task_SiteDB_MoveBet_Manual_CheckMovement] @checkAction = 1, @winlostdate = @runningDate

	--step 2: check insert/update
	EXEC [dbo].[Task_SiteDB_MoveBet_Manual_CheckOverridden] @checkAction = 1, @winlostdate = @runningDate

	--step 3: check validation
	exec [dbo].[Task_DailySummary_Verify_4_SiteDB]	@winlostdate = @runningDate

	SET @runningIdx += 1;
END', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SiteDB_SyncTicket', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220914, 
		@active_end_date=20220921, 
		@active_start_time=50000, 
		@active_end_time=235959, 
		@schedule_uid=N'0c76705a-d458-46e5-ab99-258aab9a991f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


