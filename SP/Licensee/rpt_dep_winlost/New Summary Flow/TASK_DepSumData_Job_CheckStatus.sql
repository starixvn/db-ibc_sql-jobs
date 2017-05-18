USE [bodb_Report]
GO
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job_CheckStatus]
AS
	/*
		Created By: Francis
		Created Date: 20161010
		Task: Check Status for Deposit Summary Data Job	
		DB: DBRPT.bodb_Report
		Revisions:
		-20161101@Francis: Add Opening Balance checking function
		-20161102@Francis: Only check at the beginning and middle of the day
		-20161107@Francis: Add new LogType = 5 (checkStatus) for checking status routine
		-20170328@Paul: Implement Cash Out [RedmineID :#71727]
		-20170516@Harper:  Show detail for real customer and check translog table [RedmineID: #76208]
		Input Params:	
	*/
BEGIN

	SET NOCOUNT ON
	DECLARE @CurrentDate DATE, @Yesterday DATE, @CurrentHour TINYINT, @CheckStatusCount TINYINT
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112), @Yesterday = DATEADD(DAY,-1,@CurrentDate)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	SELECT @CheckStatusCount = COUNT(LogID) FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND StatusID = 1 AND LogType = 5
	
	IF ((@CurrentHour = 1 AND @CheckStatusCount < 1) OR (@CurrentHour = 13 AND @CheckStatusCount < 2)) --Check 2 times perday, at the beginning and the mddile of the day
	BEGIN
	
		DECLARE @LogID BIGINT,
			@FailedHour TINYINT,
			@Count SMALLINT = 0,
			@Date DATE,
			@Subject VARCHAR(500) = '',
			@ErrMsg VARCHAR(500) = '',
			@ErrorMessage VARCHAR(8000)

		DECLARE @ErrMsgTab AS TABLE (NoID SMALLINT IDENTITY (1,1), JobType VARCHAR(50), ErrMsg VARCHAR(500))
		
		--Insert Log
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Log(Logdate, LogHour, LogType, StartTime)
		SELECT @CurrentDate, @CurrentHour, 5, CURRENT_TIMESTAMP AS StartTime
		
		SELECT @LogID = @@IDENTITY
					
		SELECT @Date = MIN(Winlostdate)
		FROM dbo.rptDepWinlost_Main WITH (NOLOCK)

		--Check the adequacy of summarized days
		WHILE (@Date <= @CurrentDate)
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE Winlostdate = @Date)
			BEGIN
				SELECT @ErrMsg = 'Missing data on: ' + CONVERT(VARCHAR(20),@Date)
				INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'ADEQUACY OF SUMMARIZED DAYS', @ErrMsg
			END
			SELECT @Date = DATEADD(DAY,1,@Date)
		END

		--Check realtime job status
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
							  
		--Check hourly job status
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

		--Check daily job status
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
		
		--Check opening balance of customers for yesterday only
		CREATE TABLE #Result(CustID INT, Currency INT, OpeningBalance_DepWL MONEY, OpeningBalance_Bettrans MONEY)

		-- Get opening balance of customer from rptDepWinlost_Main & bettrans
		INSERT INTO #Result(CustID, Currency, OpeningBalance_DepWL, OpeningBalance_Bettrans)
		SELECT DepWL.CustID, DepWL.currency, DepWL.OpeningBalance, bettrans.OpeningBalance
			FROM (
					SELECT m.CustID, m.currency, m.OpeningBalance
					FROM bodb_Report.dbo.rptDepWinlost_Main m WITH(NOLOCK)
					WHERE m.Winlostdate = @Yesterday
				) DepWL
				CROSS APPLY (
					SELECT 
						ISNULL( 
							SUM(
								CASE
									WHEN b.bettype IN (903, 913, 914) THEN 0
									ELSE (b.winlost - b.actual_stake + b.playercomm)
								END
							), 0
						) AS OpeningBalance
					FROM bodb02.dbo.bettrans b WITH(NOLOCK, INDEX = IX_Report)
					WHERE b.winlostdate < @Yesterday
						AND b.custid = DepWL.CustID
				) bettrans
			WHERE DepWL.OpeningBalance != bettrans.OpeningBalance
		
		SELECT @Count = @@ROWCOUNT
		
		DECLARE @haveRealCurrency BIT = 0
	
		IF EXISTS (SELECT TOP 1 1 FROM #Result WHERE Currency != 20)
			SET @haveRealCurrency = 1
			
		IF @Count > 0
		BEGIN
			-- Get list of licensee
			DECLARE @CustomerIDs VARCHAR(1000)
			SELECT	@CustomerIDs = COALESCE(@CustomerIDs + ',', '') + CONVERT(VARCHAR(10), CustID) FROM #Result

			SELECT @ErrMsg = ''
			SELECT @ErrMsg = 'Opening balances of ' + CONVERT(VARCHAR(20),@Count) +  ' customer(s) ' 
							 + '(Including: ' + @CustomerIDs + ') '						 
							 + CASE @haveRealCurrency 
									WHEN 1 THEN '(include customer(s) with real currencies) '							
									ELSE '(all are test currency) ' 
							   END
							 + 'are different compared with bettrans on: ' + CONVERT(VARCHAR(20),@Yesterday)
							 + CHAR(13) --Line break
			INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'OPENING BALANCE', @ErrMsg

			-- Check data in translog table
			DECLARE @tranlog AS TABLE (Info NVARCHAR(200))

			INSERT INTO @tranlog( Info )
			SELECT DISTINCT (CONVERT(VARCHAR(20), lg.eventID) + ', ' + CONVERT(VARCHAR(20), lg.gameID) + ', ' + s.SportName) AS Info
			FROM bodb02.dbo.translog lg WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Sports s WITH (NOLOCK) ON lg.productID = s.SportType
				--INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON lg.eventID = m.matchid
				--INNER JOIN @SportBettype s ON s.Bettype = lg.gameID
			WHERE statusID IN (0,1) AND lg.winlostdate = @Yesterday

			SELECT @Count = @@ROWCOUNT
			IF @Count > 0
			BEGIN
				DECLARE @translogInfo NVARCHAR(1000)
				SELECT @translogInfo = COALESCE(@translogInfo + CHAR(13) + CHAR(10), '') + CONVERT(NVARCHAR(200), Info) FROM @tranlog

				SELECT @ErrMsg = ''
				SELECT @ErrMsg = 'We have running ticket in translog table. Below is the list, include MatchID, Bettype and SportTypeName: '
								+ @translogInfo
								+ CHAR(13)

				INSERT INTO @ErrMsgTab (JobType, ErrMsg) SELECT 'OPENING BALANCE', @ErrMsg
			END
		END

		DROP TABLE #Result

		IF EXISTS (SELECT TOP 1 1 FROM @ErrMsgTab)
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
			
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'dbaadmin@starixsoft.com'
						, @subject = @subject
						, @body = @ErrorMessage
						, @body_format = 'HTML'
		END
	
	UPDATE bodb_Report.dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = 'Date checked: ' +  CONVERT(VARCHAR(20),@CurrentDate) + '; Type: checkStatus'
			, StatusID = 1
		WHERE LogID = @LogID
	
	END
	ELSE
	RETURN
	
END