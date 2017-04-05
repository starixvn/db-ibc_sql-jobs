USE [msdb]
GO

/****** Object:  Job [bodb_LicenseeReport: Temp job to gen and send MGC report]    Script Date: 4/5/2017 4:59:20 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 4/5/2017 4:59:20 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb_LicenseeReport: Temp job to gen and send MGC report', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'vnDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Compose and send report]    Script Date: 4/5/2017 4:59:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Compose and send report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @FromDate datetime, @ToDate datetime

SELECT @ToDate  = CAST(DATEADD(DAY,1,GETDATE()) AS DATE)
SELECT @FromDate = DATEADD (DAY,-1,@ToDate)

EXEC dbo.Task_Microgaming_Bettrans @Winlossdate = @FromDate
EXEC dbo.Task_Microgaming_Bettrans @Winlossdate = @ToDate

DECLARE @strsubject VARCHAR(100)
SELECT @strsubject = ''MGC Data from '' + CONVERT(varchar(20), @FromDate, 110) + '' to '' + CONVERT(varchar(20), @ToDate, 110)

CREATE TABLE #TempTable (RptDate smalldatetime, Currency varchar(20), BetCount int, TurnOver money, CustomerWL money, Contribution money, NetWin money)

--GMT-4
INSERT INTO #TempTable (RptDate, Currency, BetCount, TurnOver, CustomerWL, Contribution, NetWin)
	SELECT r.RptDate, 
		CASE WHEN r.CurrencyId IN (20,51) THEN e.currency ELSE e.Code END CurrencyName, 
		SUM(r.BetCount) BetCount, 
		SUM(r.Turnover) Turnover, 
		SUM(r.Winloss) CustomerWL,
		SUM(ROUND(r.ProgressiveContribution,2)) Contribution,
		SUM(-r.Winloss - ROUND(r.ProgressiveContribution,2)) NetWin
	FROM rpt_ThirdPartyWL_ExtraGMT r (NOLOCK)
		INNER JOIN bodb02..Exchange e(NOLOCK) ON r.CurrencyId = e.exchangeid
	WHERE r.RptDate BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
		AND StatusId NOT IN (-1, 101, 102)
		AND r.CurrencyId <> 20
		AND r.BetTypeId BETWEEN 2001 AND 2009
	GROUP BY r.RptDate, CASE WHEN r.CurrencyId IN (20,51) THEN e.currency ELSE e.Code END
	ORDER BY r.RptDate
	
	DECLARE @tableHTML  NVARCHAR(max);
	
	SET @tableHTML =
		N''<H1>MGC Data from '' + CONVERT(varchar(20), @FromDate, 110) + '' to '' + CONVERT(varchar(20), @ToDate, 110) + '' </H1>'' +
		N''<H2>GMT-4</H2>'' +
		N''<table border="1">'' +
		N''<tr><th>RptDate</th><th>Currency</th>'' +
		N''<th>BetCount</th><th>TurnOver</th>'' +
		N''<th>CustomerWL</th>'' +
		N''<th>Contribution</th>'' +
		N''<th>NetWin</th></tr>'' +
		CAST ( ( SELECT td = CAST(RptDate AS DATE), '''',
	                    td = Currency, '''',
	                    td = BetCount, '''',
	                    td = TurnOver, '''',
	                    td = CustomerWL, '''',
	                    td = Contribution, '''',
	                    td = NetWin
				  FROM #TempTable
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX)) +
		
		CAST ( ( SELECT td = ''Total'', '''',
	                    td = Currency, '''',
	                    td = SUM(BetCount), '''',
	                    td = SUM(Turnover), '''',
	                    td = SUM(CustomerWL), '''',
	                    td = SUM(Contribution), '''',
	                    td = SUM(NetWin)
				  FROM #TempTable
				  GROUP BY Currency
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX)) +
		N''</table>'';

--GMT0
TRUNCATE TABLE #TempTable
INSERT INTO #TempTable (RptDate, Currency, BetCount, TurnOver, CustomerWL, Contribution, NetWin)
	SELECT	
		r.RptDate3rd, 
		CASE WHEN r.CurrencyId IN (20,51) THEN e.currency ELSE e.Code END CurrencyName, 
		SUM(r.BetCount) BetCount, 
		SUM(r.Turnover) Turnover, 
		SUM(r.Winloss) CustomerWL,
		SUM(ROUND(r.ProgressiveContribution,2)) Contribution,
		SUM(-r.Winloss - ROUND(r.ProgressiveContribution,2)) NetWin
	FROM rpt_ThirdPartyWL_ExtraGMT r (NOLOCK)
		INNER JOIN bodb02..Exchange e (NOLOCK) ON r.CurrencyId = e.exchangeid
	WHERE r.RptDate3rd BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
		AND StatusId NOT IN (-1, 101, 102)
		AND r.CurrencyId <> 20
		AND r.BetTypeId BETWEEN 2001 AND 2009
	GROUP BY r.RptDate3rd, CASE WHEN r.CurrencyId IN (20,51) THEN e.currency ELSE e.Code END
	ORDER BY r.RptDate3rd

	SET @tableHTML = @tableHTML +
		N''<H2>GMT0</H2>'' +
		N''<table border="1">'' +
		N''<tr><th>RptDate</th><th>Currency</th>'' +
		N''<th>BetCount</th><th>TurnOver</th>'' +
		N''<th>CustomerWL</th>'' +
		N''<th>Contribution</th>'' +
		N''<th>NetWin</th></tr>'' +
		CAST ( ( SELECT 
						td = CAST(RptDate AS DATE), '''',
	                    td = Currency, '''',
	                    td = BetCount, '''',
	                    td = TurnOver, '''',
	                    td = CustomerWL, '''',
	                    td = Contribution, '''',
	                    td = NetWin
				  FROM #TempTable
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX)) +
		
		CAST ( ( SELECT 
						td = ''Total'', '''',
	                    td = Currency, '''',
	                    td = SUM(BetCount), '''',
	                    td = SUM(Turnover), '''',
	                    td = SUM(CustomerWL), '''',
	                    td = SUM(Contribution), '''',
	                    td = SUM(NetWin)
				  FROM #TempTable
				  GROUP BY Currency
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX)) +
		N''</table>'' +
		''<H4> This is an automail, please do not reply!!!</H4>'' ;
	
EXEC msdb.dbo.sp_send_dbmail
@recipients=''jackal.chien@onelab.tw'',
@subject = @strsubject,
@body = @tableHTML,
@body_format = ''HTML''
,@copy_recipients =''francis.le@starixsoft.com;ann.nguyen@starixsoft.com;it@starixsoft.com''	
	
--PRINT @tableHTML
	
DROP TABLE #TempTable', 
		@database_name=N'bodb_LicenseeReport', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Everyday at 10PM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160414, 
		@active_end_date=99991231, 
		@active_start_time=221500, 
		@active_end_time=235959, 
		@schedule_uid=N'08e4e187-a53d-484e-ace0-ef7c6db6b06a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


