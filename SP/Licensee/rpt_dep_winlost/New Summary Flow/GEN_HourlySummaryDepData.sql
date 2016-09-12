USE [bodb02]
GO
ALTER PROCEDURE [dbo].[GEN_HourlySummaryDepData]
	@Winlostdate SMALLDATETIME,
	@NumberofCus INT = 0 OUTPUT,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160816
		Task: Generate data for Deposit Data summary system for one winlostdate from bettrans	
		DB: DBACC.bodb02
		Revisions:
		Input Params:	
		- @Winlostdate: The input Winlostdate to be summarized
		- @NumberofCus: The number of customer have been summarized
		- @isSuccessful: -1: Data of the whole day has been summarized completely
						 -0: Data of the whole day has not been summarized completely
	*/
BEGIN
	IF @Winlostdate > CURRENT_TIMESTAMP OR NOT EXISTS (SELECT TOP 1 1 FROM dbo.bettrans WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
		BEGIN
			PRINT 'EXEC GEN_HourlySummaryDepData: There is no data in bettrans to summarize or input @Winlostdate is greater than current day ==> RETURN'
			RETURN
		END
	DECLARE @i TINYINT = 1
	DECLARE @PreviousDay DATE = DATEADD(DAY,-1,@WinlostDate)
	
	CREATE TABLE #rptDepWinlost_Main (CustID INT, OpeningBalance MONEY DEFAULT (0)
											  UNIQUE CLUSTERED (CustID))
	
	BEGIN TRY 
		--1. Call SP to summarize data for rptDepWinlost_Trans
		EXEC dbo.TASK_RealtimeSummaryDepData @Winlostdate = @Winlostdate, @isSuccessful = @isSuccessful OUTPUT
		--1.Retry 3 times if failed
		WHILE (@i <= 3 AND @isSuccessful = 0)
			BEGIN
				WAITFOR DELAY '00:00:01.000'
				EXEC dbo.TASK_RealtimeSummaryDepData @Winlostdate = @Winlostdate, @isSuccessful = @isSuccessful OUTPUT
				SELECT @i = @i + 1 
			END
		IF @isSuccessful = 1
			SET @isSuccessful = 0
		ELSE
			BEGIN
				PRINT 'EXEC GEN_HourlySummaryDepData: Unsuccessfully generated data for rptDepWinlost_Trans ==> RETURN'
				RETURN
			END
		--2.Check if the input @Winlostdate's data has not been summarized for rptDepWinlost_Main
		IF NOT EXISTS (SELECT TOP 1 1 FROM bodb_Report.dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE winlostdate = @Winlostdate)
		BEGIN
			--Insert if not exists
			INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
				SELECT @Winlostdate, m.CustID
						, (m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
						   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
						   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0))--compute @Winlostdate's OpeningBalance
						, m.actualrate, m.srecommend, m.mrecommend, m.recommend, m.currency
				FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
					LEFT JOIN bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
					ON m.Winlostdate = t.Winlostdate AND m.CustID = t.CustID AND t.SportType = -1 AND t.PartnerID = -1 --only get attributes of rptDepWinlost
				WHERE m.Winlostdate = @PreviousDay
			SELECT @NumberofCus = @@ROWCOUNT
		END
		ELSE
		BEGIN
			--Update OpeningBalance if exists
			INSERT INTO #rptDepWinlost_Main (CustID, OpeningBalance)
				SELECT m.CustID
					   , (m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
						   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
						   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0))--compute @Winlostdate's OpeningBalance
				FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
					 INNER JOIN bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
					 ON m.Winlostdate = t.Winlostdate AND m.CustID = t.CustID AND t.SportType = -1 AND t.PartnerID = -1--only get attributes of rptDepWinlost
				WHERE m.Winlostdate = @PreviousDay
			
			UPDATE m
			SET m.OpeningBalance = t.OpeningBalance
			FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (ROWLOCK, UPDLOCK) 
				INNER JOIN #rptDepWinlost_Main t ON m.CustID = t.CustID AND m.Winlostdate = @Winlostdate
			SELECT @NumberofCus = @@ROWCOUNT 
		END
		
		--3.Insert customers that are missing from rptDepWinlost_Main compared with rptDepwinlost_Trans 
		TRUNCATE TABLE #rptDepWinlost_Main
		INSERT INTO #rptDepWinlost_Main (CustID)
		SELECT CustID
		FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (NOLOCK) 
		WHERE Winlostdate = @Winlostdate
			  AND SportType = -1 AND PartnerID = -1 --only get attributes of rptDepWinlost
			  AND CustID NOT IN (SELECT CustID FROM bodb_Report.dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE Winlostdate = @Winlostdate)
		
		UPDATE mt
		SET mt.OpeningBalance = temp.OpeningBalance
		FROM #rptDepWinlost_Main mt
			INNER JOIN 
			(SELECT m.CustID
					, m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
						   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
						   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0) AS OpeningBalance
			 FROM bodb_Report.dbo.rptDepWinlost_Main m 
				  INNER JOIN bodb_Report.dbo.rptDepWinlost_Trans t
				  ON t.CustID = m.CustID AND m.Winlostdate = @PreviousDay AND t.Winlostdate = @PreviousDay) temp 
			ON mt.CustID = temp.CustID
			
		INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
			SELECT @Winlostdate, t.CustID, t.OpeningBalance, e.ActualRate, c.srecommend, c.mrecommend, c.recommend, c.currency
			FROM #rptDepWinlost_Main t
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON t.CustID = c.custid AND c.roleid = 1
			INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) ON c.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate
			
		SELECT @NumberofCus = @NumberofCus + @@ROWCOUNT
		
		SET @isSuccessful = 1	
	END TRY
	BEGIN CATCH
		PRINT 'EXEC GEN_HourlySummaryDepData, Winlostdate = ' + CONVERT(VARCHAR(20),@Winlostdate,112) + ', ErrMsg: ' + ERROR_MESSAGE()
		SET @isSuccessful = 0
	END CATCH
	
	DROP TABLE #rptDepWinlost_Main
END

