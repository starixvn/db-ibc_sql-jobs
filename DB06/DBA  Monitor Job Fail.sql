USE [msdb]
GO

/****** Object:  Job [DBA : Monitor Job Fail]    Script Date: 01/15/2015 22:37:37 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/15/2015 22:37:37 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA : Monitor Job Fail', 
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
/****** Object:  Step [Monitor Job Fail]    Script Date: 01/15/2015 22:37:37 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Job Fail', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
create table #Failed_Jobs (
	[Status] [varchar](12) NOT NULL,
	[Job Name] [varchar](120) NULL,
	[Step ID] [varchar](5) NULL,
	[Step Name] [varchar](30) NULL,
	[Start Date Time] [varchar](30) NULL,
	[Message] [nvarchar](4000) NULL)

insert into #Failed_Jobs
select Status = CASE sjh. run_status 
			when 0 then ''Failed''
			when 1 then ''Succeeded''
			when 2 then ''Retry''
			when 3 then ''Canceled''
			ELSE ''In progress''
		END,
       cast(sj.name as varchar(120)) as "Job Name",
       cast(sjs.step_id as varchar(5)) as "Step ID",
       cast(sjs.step_name as varchar(30)) as "Step Name",
       cast(REPLACE(CONVERT(varchar,convert(datetime,convert(varchar,sjh.run_date)),102),''.'',''-'')+'' ''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),1,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),3,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),5,2) as varchar(30)) ''Start Date Time'',
       sjh.message as "Message"
from sysjobs sj
join sysjobsteps sjs 
 on sj.job_id = sjs.job_id
join sysjobhistory sjh 
 on sj.job_id = sjh.job_id and sjs.step_id = sjh.step_id
where sjh.run_status <> 1
  and cast(sjh.run_date as float)*1000000+sjh.run_time > 
       CAST (CONVERT(varchar(8),DATEADD(MI,-30,getdate()),112) --YMD
	+ SUBSTRING( CONVERT(varchar(20),DATEADD(MI,-30,getdate()),20),12,2) --hr
	+ SUBSTRING( CONVERT(varchar(20),DATEADD(MI,-30,getdate()),20),15,2) --min
	+ ''00'' as float)
union
select Status = CASE sjh. run_status 
			when 0 then ''Failed''
			when 1 then ''Succeeded''
			when 2 then ''Retry''
			when 3 then ''Canceled''
			ELSE ''In progress''
		END,
       cast(sj.name as varchar(120)) as "Job Name",
       ''MAIN'' as "Step ID",
       ''MAIN'' as "Step Name",
       cast(REPLACE(CONVERT(varchar,convert(datetime,convert(varchar,sjh.run_date)),102),''.'',''-'')+'' ''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),1,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),3,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),5,2) as varchar(30)) ''Start Date Time'',
       sjh.message as "Message"
from sysjobs sj
join sysjobhistory sjh 
 on sj.job_id = sjh.job_id
where sjh.run_status <> 1 and sjh.step_id=0
  and cast(sjh.run_date as float)*1000000+sjh.run_time >
       CAST (CONVERT(varchar(8),DATEADD(MI,-30,getdate()),112) --YMD
	+ SUBSTRING( CONVERT(varchar(20),DATEADD(MI,-30,getdate()),20),12,2) --hr
	+ SUBSTRING( CONVERT(varchar(20),DATEADD(MI,-30,getdate()),20),15,2) --min
	+ ''00'' as float)

declare @cnt int  
--select @cnt=COUNT(1) from #Failed_Jobs where [Job name] not in (''DB07-bodb_Message-message_table-DBKRA-6'',''DB07-bodb_Message-DB07_bodb_message_IOM-DBIOMA2-28'') 
select @cnt=COUNT(1) from #Failed_Jobs where [Job name] not in (''bodb02 : Log Digger'',''Thien : DB06_bodb_archive : Backup data to DB052_bodb_archive (After Joe''''s Thursday routine)'',''winlost report update (daily)'',''BetBackup : clear old bet'',''bodb02 : WinLost report update'',''Task : Replication for DBTrans.bodb02.dbo.UserLog'',''Task : Replication for DB02.bodb02.dbo.UserLog'',''Thien : MANUALLY_DB06_bodb_archive : Archive data to DBSPARE.bodb_archive13 (please ignore all the error messages)'')
if (@cnt > 0)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check the following failed jobs on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Failed Jobs Listing - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>Status</th><th>Job Name</th>'' +
		N''<th>Step ID</th><th>Step Name</th><th>Start Date</th>'' +
		N''<th>Message</th></tr>'' +
		CAST ( ( SELECT td = [Status], '''',
	                    td = [Job Name], '''',
	                    td = [Step ID], '''',
	                    td = [Step Name], '''',
	                    td = [Start Date Time], '''',
	                    td = [Message]
		  --FROM #Failed_Jobs where [Job name] not in (''DB07-bodb_Message-message_table-DBKRA-6'',''DB07-bodb_Message-DB07_bodb_message_IOM-DBIOMA2-28'') 
		  FROM #Failed_Jobs where [Job name] not in (''bodb02 : Log Digger'',''Thien : DB06_bodb_archive : Backup data to DB052_bodb_archive (After Joe''''s Thursday routine)'',''winlost report update (daily)'',''BetBackup : clear old bet'',''bodb02 : WinLost report update'',''Task : Replication for DBTrans.bodb02.dbo.UserLog'',''Task : Replication for DB02.bodb02.dbo.UserLog'',''Thien : MANUALLY_DB06_bodb_archive : Archive data to DBSPARE.bodb_archive13 (please ignore all the error messages)'')
		  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	--@from_address=''test@onelab.tw'',
	@recipients=''dbaadmin@onelab.tw'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' 
	--@profile_name=''DBDISTRMProfile''
end

drop table #Failed_Jobs', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Schedule-1', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121226, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'c7859539-1a14-4634-87f5-e381c1c83ca5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


