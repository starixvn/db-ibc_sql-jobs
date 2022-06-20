/*<info serverAlias="DBRPT-bodb_report" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job_CheckStatus]
AS
/*
	Created: 20161010@Francis
	Task: Check Status for Deposit Summary Data Job
	DB: DBRPT.bodb_Report
	
	Revisions:
		- 20161101@Francis: Add Opening Balance checking function
		- 20161102@Francis: Only check at the beginning and middle of the day
		- 20161107@Francis: Add new LogType = 5 (checkStatus) for checking status routine
		- 20170328@Paul: Implement Cash Out [RedmineID :#71727]
		- 20170516@Harper:  Show detail for real customer and check translog table [RedmineID: #76208]
		- 20170725@Sophia: Exclude Cashout WL when compare Openning Balance [RedmineID: #79346]
		- 20190624@Percy: Check missing import data in the last 15 mins + Remove UUS currency [RedmineID: #115411]
		- 20201012@Malcolm :  Change email Starixsoft.com to starixvn.com [RedmineId : #143312]
		- 20210518@Percy: Change code to adapt new Move Bets flow [RedmineID: #154866]
		- 20220124@Sophia: Remove the code Gen data for Old Cashout [Redmine: #167928]
		- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - [RedmineID: #164301]
		- 20220321@Percy: Enhance code check Opening Balance [RedmineID: #170118]
		- 20220620@Sol: Enhance code to prevent arithmetic overflow [RedmineID: #174296]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurrentDate DATE, @Yesterday DATE, @CurrentHour TINYINT, @CheckStatusCount TINYINT
	SELECT  @CurrentDate = CONVERT(DATE, CURRENT_TIMESTAMP, 112), @Yesterday = DATEADD(DAY, -1, @CurrentDate)
	SELECT  @CurrentHour = DATEPART(HOUR, CURRENT_TIMESTAMP)

	DECLARE @LogID BIGINT,
			@FailedHour TINYINT,
			@Count INT = 0,
			@Date DATE,
			@Subject VARCHAR(500) = '',
			@ErrMsg VARCHAR(MAX) = '',
			@ErrorMessage VARCHAR(MAX)

	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MoveBetsDay FROM @MBBU

	DECLARE @ErrMsgTab AS TABLE (NoID SMALLINT IDENTITY (1,1), JobType VARCHAR(50), ErrMsg VARCHAR(MAX))
	
	-- Check job working or not in the last 15 mins
	DECLARE @EndImportTime DATETIME
	SELECT  @EndImportTime = MAX(EndTime) FROM dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate

	IF @EndImportTime IS NULL
		SELECT @EndImportTime = @CurrentDate

	DECLARE @IsJobImporting BIT
	SELECT  @IsJobImporting = MAX(CONVERT(TINYINT, VValue)) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isArchivingDEPdata', 'isSummaryingDEPdata')

	IF @IsJobImporting = 1 AND DATEDIFF(MINUTE, @EndImportTime, CURRENT_TIMESTAMP) >= 15
	BEGIN
		SELECT @ErrMsg = 'Job failed on: ' + CONVERT(VARCHAR(20), @CurrentDate)
						  + ', isArchivingDEPdata/isSummaryingDEPdata = 1 and EndTime on rptDepWinlost_Log has not been updated in the last 15 mins' + CHAR(13) -- Line break
		
		INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'ALL', @ErrMsg
	END
	-- End Check job working or not in the last 15 mins

	-- Check 2 times per day, at the beginning and the middle of the day
	SELECT @CheckStatusCount = COUNT(LogID) FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND StatusID = 1 AND LogType = 5
	
	IF ((@CurrentHour = 1 AND @CheckStatusCount < 1) OR (@CurrentHour = 13 AND @CheckStatusCount < 2)) 
	BEGIN
		--Insert Log
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Log(Logdate, LogHour, LogType, StartTime)
		SELECT @CurrentDate, @CurrentHour, 5, CURRENT_TIMESTAMP AS StartTime
		
		SELECT @LogID = @@IDENTITY
					
		SELECT @Date = MIN(Winlostdate)
		FROM dbo.rptDepWinlost_Main WITH (NOLOCK)

		-- Check the adequacy of summarized days
		WHILE (@Date <= @CurrentDate)
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE Winlostdate = @Date)
			BEGIN
				SELECT @ErrMsg = 'Missing data on: ' + CONVERT(VARCHAR(20),@Date)
				INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'ADEQUACY OF SUMMARIZED DAYS', @ErrMsg
			END
			SELECT @Date = DATEADD(DAY,1,@Date)
		END

		-- Check realtime job status
		SELECT TOP 1 @FailedHour = LogHour, @Count = ISNULL(COUNT(LogID),0)
		FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
		WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogType = 4
		GROUP BY LogHour
		HAVING COUNT(LogID) >= 10
		ORDER BY COUNT(LogID) DESC
		
		IF @Count > 0
		BEGIN
			SELECT @ErrMsg = 'Realtime job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@FailedHour) 
							+ CASE WHEN @FailedHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
			INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'REALTIME', @ErrMsg
		END
							  
		-- Check hourly job status
		SELECT @ErrMsg = ''
		SELECT TOP 1 @FailedHour = LogHour, @Count = ISNULL(COUNT(LogID),0)
		FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
		WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogType = 3
		GROUP BY LogHour
		HAVING COUNT(LogID) >= 4
		ORDER BY COUNT(LogID) DESC
		
		IF @Count > 0
		BEGIN
			SELECT @ErrMsg = 'Hourly job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@FailedHour) 
						  + CASE WHEN @FailedHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
			INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'HOURLY', @ErrMsg
		END

		-- Check daily job status
		SELECT @ErrMsg = ''
		SELECT TOP 1 @FailedHour = LogHour, @Count = ISNULL(COUNT(LogID),0)
		FROM dbo.rptDepWinlost_Log WITH (NOLOCK)
		WHERE StatusID = 0 AND LogDate = @CurrentDate AND LogType = 2
		GROUP BY LogHour
		HAVING COUNT(LogID) >= 3
		ORDER BY COUNT(LogID) DESC
		
		IF @Count > 0
		BEGIN
			SELECT @ErrMsg = 'Daily job failed for ' + CONVERT(VARCHAR(20),@Count) + ' time(s) on: ' + CONVERT(VARCHAR(20),@FailedHour) 
							  + CASE WHEN @FailedHour < 12 THEN ' AM ' ELSE ' PM ' END + 'range, day: ' + CONVERT(VARCHAR(20),@CurrentDate) + CHAR(13) --Line break
		
			INSERT INTO @ErrMsgTab (Jobtype, ErrMsg) SELECT 'DAILY', @ErrMsg
		END	
		
		-- Check opening balance of customers for yesterday only
		---- Gen data for TradeCust Winlost on the days when move bets
		
		---EXEC dbo.GEN_rptTradeCustWinlost  ---- 20220124: remove Code Gen Old Cashout

		-- Get opening balance of customer from rptDepWinlost_Main & bettrans
		CREATE TABLE #rptDepWinlost_Main (CustId INT PRIMARY KEY, OpeningBalance MONEY)
		INSERT INTO #rptDepWinlost_Main (CustId, OpeningBalance)
		SELECT m.CustID, m.OpeningBalance
		FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK)
		WHERE m.Winlostdate = @Yesterday AND m.currency <> 20

		CREATE TABLE #rptTradeCustWinlost (CustId INT PRIMARY KEY, Winloss MONEY)
		INSERT INTO #rptTradeCustWinlost (CustId, Winloss)
		SELECT CustID, SUM(Winloss) AS Winloss
		FROM bodb_Report.dbo.rptTradeCustWinlost WITH (NOLOCK)
		GROUP BY CustID

		CREATE TABLE #bettrans (CustId INT PRIMARY KEY, OpeningBalance MONEY)
		INSERT INTO #bettrans (CustId, OpeningBalance)
		SELECT CustID, SUM(b.winlost - b.actual_stake + b.playercomm) AS Winloss
		FROM bodb02.dbo.bettrans b WITH(NOLOCK) 					
		WHERE b.winlostdate < @Yesterday AND winlostdate > @MoveBetsDay
			AND bettype NOT IN (903, 913, 914)
		GROUP BY b.custid

		CREATE TABLE #Transfer (CustId INT PRIMARY KEY, OpeningBalance MONEY)
		INSERT INTO #Transfer (CustId, OpeningBalance)
		SELECT CustId, SUM(OpeningBalance)
		FROM (
			SELECT b.CustID, SUM(b.winlost - b.actual_stake) AS OpeningBalance
			FROM bodb02.dbo.Transfer b WITH (NOLOCK)
			WHERE bettype >= 20000
				AND b.WinlostDate < @Yesterday
			GROUP BY CustID
			UNION ALL
			SELECT b.CustID, SUM(b.winlost - b.actual_stake + b.PlayerComm) AS OpeningBalance
			FROM #rptDepWinlost_Main r
				INNER LOOP JOIN bodb02.dbo.Transfer b WITH (NOLOCK) ON r.CustId = b.CustId -- force index seek on CustId
			WHERE bettype = 19999
				AND b.WinlostDate <= @MoveBetsDay
			GROUP BY b.CustID
		) t
		GROUP BY CustId

		CREATE TABLE #Result (CustID INT, OpeningBalance_DepWL MONEY, OpeningBalance_Bettrans MONEY)
		INSERT INTO #Result (CustID, OpeningBalance_DepWL, OpeningBalance_Bettrans)
		SELECT r.CustID, r.OpeningBalance, ISNULL(b.OpeningBalance, 0) + ISNULL(t.OpeningBalance, 0) - ISNULL(c.Winloss, 0)
		FROM #rptDepWinlost_Main r
			LEFT JOIN #bettrans b ON r.CustId = b.CustId
			LEFT JOIN #Transfer t ON r.CustId = t.CustId
			LEFT JOIN #rptTradeCustWinlost c ON r.CustID = c.CustID
		WHERE (b.CustId IS NOT NULL OR t.CustId IS NOT NULL)
			AND (r.OpeningBalance <> ISNULL(b.OpeningBalance, 0) + ISNULL(t.OpeningBalance, 0) - ISNULL(c.Winloss, 0))
			
		SELECT @Count = @@ROWCOUNT
		
		IF @Count > 0
		BEGIN
			-- Get list of licensee
			DECLARE @CustomerIDs VARCHAR(MAX)
			SELECT TOP 100 @CustomerIDs = COALESCE(@CustomerIDs + ',', '') + CONVERT(VARCHAR(10), CustID) FROM #Result

			SELECT @ErrMsg = ''
			SELECT @ErrMsg = 'Opening balances of ' + CONVERT(VARCHAR(20),@Count) +  ' real customer(s) ' 							 					 
							 + 'are different compared with bettrans on: ' + CONVERT(VARCHAR(20), @Yesterday)
							 + CHAR(10) + CHAR(13) -- Line break
							 + '. List of customers with real currencies: ' + @CustomerIDs							
							 + CHAR(13) -- Line break
			INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'OPENING BALANCE', @ErrMsg

			-- Check data in translog table
			DECLARE @tranlog AS TABLE (Info NVARCHAR(200))

			INSERT INTO @tranlog(Info)
			SELECT DISTINCT (CONVERT(VARCHAR(20), lg.eventID) + ', ' + CONVERT(VARCHAR(20), lg.gameID) + ', ' + s.SportName) AS Info
			FROM bodb02.dbo.translog lg WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Sports s WITH (NOLOCK) ON lg.productID = s.SportType
				--INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON lg.eventID = m.matchid
				--INNER JOIN @SportBettype s ON s.Bettype = lg.gameID
			WHERE statusID IN (0,1) AND lg.winlostdate = @Yesterday
					AND EXISTS (SELECT 1 FROM #Result r WHERE r.CustID = lg.custid)

			SELECT @Count = @@ROWCOUNT
			
			IF @Count > 0
			BEGIN
				DECLARE @translogInfo NVARCHAR(1000)
				SELECT @translogInfo = COALESCE(@translogInfo + ' - ', '') + CONVERT(NVARCHAR(200), Info) FROM @tranlog

				SELECT @ErrMsg = ''
				SELECT @ErrMsg = 'We have running ticket in translog table. Below is the list, include MatchID, Bettype and SportTypeName: '
								+ @translogInfo
								+ CHAR(13)

				INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'RUNNING TRANSLOG', @ErrMsg
			END
		END

		DROP TABLE #bettrans
		DROP TABLE #Result
		DROP TABLE #rptDepWinlost_Main
		DROP TABLE #rptTradeCustWinlost
		DROP TABLE #Transfer

		UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = 'Date checked: ' +  CONVERT(VARCHAR(20),@CurrentDate) + '; Type: checkStatus'
			,StatusID = 1
		WHERE LogID = @LogID
	END
	-- End Check 2 times per day, at the beginning and the middle of the day

	-- Send mail
	IF EXISTS (SELECT 1 FROM @ErrMsgTab)
	BEGIN
		SELECT @Subject = 'SQL Server Job System:'' bodb02: Deposit Report Summary'' completed on \\' + @@SERVERNAME
		
		SELECT @ErrorMessage = '<H3>Deposit Data Summary Job was run on ['+ CONVERT(VARCHAR(20),@CurrentDate) + ']. Status: FAILED</H3>'
								+ '<table border="1"> '
								+ '<tr><th>No.</th><th>Job type</th><th>Error Message</th></tr>'
								+ CAST(( SELECT    td = NoID, '',
													td = JobType, '',
													td = ErrMsg, ''
										FROM @ErrMsgTab
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
		
		EXEC msdb.dbo.sp_send_dbmail @recipients = 'dbaadmin@starixvn.com'
					, @subject = @subject
					, @body = @ErrorMessage
					, @body_format = 'HTML'
	END
	-- End Send mail
END
GO