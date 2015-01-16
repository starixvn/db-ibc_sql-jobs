USE [msdb]
GO

/****** Object:  Job [TGRS-Staging Data Daily]    Script Date: 01/16/2015 01:55:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/16/2015 01:55:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'TGRS-Staging Data Daily', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', 
		@notify_email_operator_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [01.Task_StagingTraderSetting]    Script Date: 01/16/2015 01:55:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'01.Task_StagingTraderSetting', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC Task_StagingTraderSetting', 
		@database_name=N'bodb_TGRS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [02.Staging Data from IBC]    Script Date: 01/16/2015 01:55:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'02.Staging Data from IBC', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC  [dbo].Task_StagingDataTGRS', 
		@database_name=N'bodb_TGRS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [03.Staging Sum Daily Table From Staging_TraderPerformance]    Script Date: 01/16/2015 01:55:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'03.Staging Sum Daily Table From Staging_TraderPerformance', 
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
DECLARE @EventDate DATE;
DECLARE db_cursor CURSOR FOR  
SELECT EventDate FROM [dbo].[Staging_TraderPerformance] WITH(NOLOCK) GROUP BY EventDate

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @EventDate   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       PRINT @EventDate
	   EXEC [dbo].[Task_StagingTraderPerformanceByDate]	@Date=@EventDate
       FETCH NEXT FROM db_cursor INTO @EventDate   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor

', 
		@database_name=N'bodb_TGRS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [04.Staging Sum Monthly Table From TraderPerformance]    Script Date: 01/16/2015 01:55:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'04.Staging Sum Monthly Table From TraderPerformance', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Month DATE;
DECLARE db_cursor CURSOR FOR  

SELECT CONVERT(VARCHAR(8),EventDate) + ''01''
FROM [dbo].[Staging_TraderPerformance] WITH(NOLOCK) 
GROUP BY CONVERT(VARCHAR(8),EventDate) + ''01''

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @Month   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       PRINT @Month
	   EXEC [dbo].[Task_StagingTraderPerformanceByMonth]	@Month=@Month
       FETCH NEXT FROM db_cursor INTO @Month   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor
 ', 
		@database_name=N'bodb_TGRS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Job TGRS-Staging Data', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140603, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'8c1a700c-f20b-4730-8810-c53e23d5306e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


