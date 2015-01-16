USE [msdb]
GO

/****** Object:  Job [Joe : job Calculate NetTurnOver]    Script Date: 01/15/2015 22:50:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/15/2015 22:50:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Joe : job Calculate NetTurnOver', 
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
/****** Object:  Step [ge]    Script Date: 01/15/2015 22:50:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ge', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
Declare @winlostdate smalldatetime
select TOP 1 @winlostdate = winlostdate
FROM netTurnOver.dbo.wld
ORDER BY rn

DELETE FROM netTurnOver.dbo.wld
WHERE winlostdate = @winlostdate

IF @@ROWCOUNT = 1
BEGIN
	
INSERT INTO netTurnOver.dbo.tmp_netTurnOver
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend,
	sporttype, bettype, netTurnover, anet, mnet, snet)
	SELECT @winlostdate, 1,	custid, recommend, mrecommend, srecommend,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END bettype, 
		0, -- netTurnover
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*apositiontaking)/2 else ABS(stake*apositiontaking) end), --netTurnover
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*mpositiontaking)/2 else ABS(stake*mpositiontaking) end), --netTurnover
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*spositiontaking)/2 else ABS(stake*spositiontaking) end) --netTurnover
	FROM
		dbo.bettrans_bk bettrans with (nolock)
	WHERE
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in (''running'',''waiting'',''VOID'',''REJECT'',''REFUND'') and
		bettrans.statusID NOT IN (0,1,102,101,103) and 
		bettrans.bettype <=19000
	GROUP BY
		custid, recommend, mrecommend, srecommend,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END
		
INSERT INTO netTurnOver.dbo.tmp_netTurnOver
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 2, recommend, recommend, mrecommend, srecommend,
		sporttype, bettype, SUM(anet)
	FROM
		netTurnOver.dbo.tmp_netTurnOver
	WHERE
		winlostdate = @winlostdate AND roleid = 1
	GROUP BY
		recommend, mrecommend, srecommend,
		sporttype, bettype

INSERT INTO netTurnOver.dbo.tmp_netTurnOver
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 3, mrecommend, 0, mrecommend, srecommend,
		sporttype, bettype, SUM(mnet)
	FROM
		netTurnOver.dbo.tmp_netTurnOver
	WHERE
		winlostdate = @winlostdate AND roleid = 1
	GROUP BY
		mrecommend, srecommend,
		sporttype, bettype

INSERT INTO netTurnOver.dbo.tmp_netTurnOver
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 4, srecommend, 0, 0, srecommend,
		sporttype, bettype, SUM(snet)
	FROM
		netTurnOver.dbo.tmp_netTurnOver
	WHERE
		winlostdate = @winlostdate AND roleid = 1
	GROUP BY
		srecommend,
		sporttype, bettype

END
ELSE
	-- raiserror here to continue to next step of jobs
	RAISERROR (''* no more data *'', -- Message text.
               16, -- Severity.
               1 -- State.
               );', 
		@database_name=N'bodb_Archive', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [lo]    Script Date: 01/15/2015 22:50:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'lo', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=1, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @a int
set @a = 1', 
		@database_name=N'master', 
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


