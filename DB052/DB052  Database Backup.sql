USE [msdb]
GO

/****** Object:  Job [DB052 : Database Backup]    Script Date: 01/08/2015 05:29:06 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/08/2015 05:29:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB052 : Database Backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBAAdmin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup]    Script Date: 01/08/2015 05:29:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @Date nvarchar(50)  
Declare @Time nvarchar(50)  
DECLARE @filename nvarchar(200)
Set @Date =
	CAST(DATEPART(year, CURRENT_TIMESTAMP) as nvarchar) +   
	CASE WHEN DATEPART(month, CURRENT_TIMESTAMP) < 10 THEN ''0'' + CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) END +   
	CASE WHEN DATEPART(day, CURRENT_TIMESTAMP)   < 10 THEN ''0'' + CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar)   ELSE CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar) END  
Set @Time =
	CASE WHEN DATEPART(hour, CURRENT_TIMESTAMP)  < 10 THEN ''0'' + CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar)  ELSE CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar) END +  
	CASE WHEN DATEPART(minute,CURRENT_TIMESTAMP) < 10 THEN ''0'' + CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) END  

Declare @Desc nvarchar(255) Set @Desc = ''Full Backup for '' + @Date  
Declare @Name nvarchar(128) Set @Name = @Date + '' '' + @Time + '' FULL_BK''


SET @filename = N''G:\BACKUP\DB052.bodb_CRM_''+ @Date +''.bak''
BACKUP DATABASE [bodb_CRM] TO  DISK = @filename
WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
NAME = @Name, SKIP, NOREWIND, COMPRESSION, NOUNLOAD

SET @filename = N''G:\BACKUP\DB052.bodb_OddsFeed_''+@Date +''_''+ @Time +''.bak''
BACKUP DATABASE [bodb_OddsFeed] TO  DISK = @filename
WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

SET @filename = N''G:\BACKUP\DB052.bodb_NAP_''+@Date +''_''+ @Time +''.bak''
BACKUP DATABASE [bodb_NAP] TO  DISK = @filename
WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

SET @filename = N''G:\BACKUP\DB052.bodb_NAPLOG_''+@Date +''_''+ @Time +''.bak''
BACKUP DATABASE [bodb_NAPLOG] TO  DISK = @filename
WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION


--BACKUP DATABASE [bodb_MoveBet] TO DISK = N''G:\BACKUP\DB052.bodb_MoveBet.bak''
--WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
--NAME = @Name, SKIP, NOREWIND, NOUNLOAD

Declare @WeekDay tinyint  
SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)  

IF @WeekDay = 7
BEGIN
	SET @filename = N''G:\BACKUP\DB052.bodb_Licensee_''+ @Date +''_FULL.bak''
	BACKUP DATABASE [bodb_Licensee] TO  DISK = @filename
	WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, COMPRESSION, NOUNLOAD

	SET @filename = N''G:\BACKUP\DB052.Affiliate_12BET_''+@Date +''_''+ @Time +''_FULL.bak''
	BACKUP DATABASE [Affiliate_12BET] TO  DISK = @filename
	WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION


	SET @filename = N''G:\BACKUP\DB052.bodb_Maintenance_''+@Date +''_''+ @Time +''_FULL.bak''
	BACKUP DATABASE [bodb_Maintenance] TO  DISK = @filename
	WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

	SET @filename = N''G:\BACKUP\DB052.bodb_RMS_''+@Date +''_''+ @Time +''_FULL.bak''
	BACKUP DATABASE [bodb_RMS] TO  DISK = @filename
	WITH  DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

END	
ELSE
BEGIN
	SET @filename = N''G:\BACKUP\DB052.bodb_Licensee_''+ @Date +''_DF.bak''
	BACKUP DATABASE [bodb_Licensee] TO  DISK = @filename
	WITH  DIFFERENTIAL, DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, COMPRESSION, NOUNLOAD

	SET @filename = N''G:\BACKUP\DB052.Affiliate_12BET_''+@Date +''_''+ @Time +''_DF.bak''
	BACKUP DATABASE [Affiliate_12BET] TO  DISK = @filename
	WITH  DIFFERENTIAL, DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

	SET @filename = N''G:\BACKUP\DB052.bodb_Maintenance_''+@Date +''_''+ @Time +''_DF.bak''
	BACKUP DATABASE [bodb_Maintenance] TO  DISK = @filename
	WITH  DIFFERENTIAL, DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

	SET @filename = N''G:\BACKUP\DB052.bodb_RMS_''+@Date +''_''+ @Time +''_DF.bak''
	BACKUP DATABASE [bodb_RMS] TO  DISK = @filename
	WITH  DIFFERENTIAL, DESCRIPTION = @Desc, NOFORMAT, INIT,  
	NAME = @Name, SKIP, NOREWIND, NOUNLOAD,COMPRESSION

END	



', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'3 times a week', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20100118, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'030645bd-97ad-433f-b3b6-82d9aa98084b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


