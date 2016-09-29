USE [bodb02]
GO
ALTER PROCEDURE [dbo].[GEN_HourlySummaryDepData_Bettrans14]
	@Winlostdate SMALLDATETIME,
	@NumberofCus INT = 0 OUTPUT,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160816
		Task: Generate data for Deposit Data summary system for one winlostdate from bettrans14 		
		DB: DBACC.bodb02
		Revisions:
		Input Params:	
		- @Winlostdate: The input Winlostdate to be summarized
		- @NumberofCus: The number of customer have been summarized
		- @isSuccessful: -1: Data of the whole day has been summarized completely
						 -0: Data of the whole day has not been summarized completely
	*/
BEGIN
	SET NOCOUNT ON
	IF @Winlostdate > CURRENT_TIMESTAMP OR NOT EXISTS (SELECT TOP 1 1 FROM dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
		BEGIN
			PRINT 'EXEC GEN_HourlySummaryDepData_Bettrans14: There is no data in bettrans to summarize or input @Winlostdate is greater than current day ==> RETURN'
			RETURN
		END
	DECLARE @i TINYINT = 1
	DECLARE @PreviousDay DATE = DATEADD(DAY,-1,@WinlostDate)
	SET @isSuccessful = 0
	
	Declare @BalanceUpDay smalldatetime
	SELECT @BalanceUpDay = winlostdate
	FROM Bettrans WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0 and custid = 3
	
	CREATE TABLE #rptDepWinlost_Main (CustID INT, OpeningBalance MONEY DEFAULT (0), actualrate FLOAT DEFAULT (0), srecommend INT, mrecommend INT, recommend INT, currency INT
											  UNIQUE CLUSTERED (CustID))
	
	BEGIN TRY 
		--1. Call SP to summarize data for rptDepWinlost_Trans
		EXEC dbo.TASK_RealtimeSummaryDepData_Bettrans14 @Winlostdate = @Winlostdate, @isSuccessful = @isSuccessful OUTPUT
		--1.Retry 3 times if failed
		WHILE (@i <= 3 AND @isSuccessful = 0)
			BEGIN
				WAITFOR DELAY '00:00:01.000'
				EXEC dbo.TASK_RealtimeSummaryDepData_Bettrans14 @Winlostdate = @Winlostdate, @isSuccessful = @isSuccessful OUTPUT
				SELECT @i = @i + 1 
			END
		IF @isSuccessful = 1
			SET @isSuccessful = 0
		ELSE
			BEGIN
				PRINT 'EXEC GEN_HourlySummaryDepData_Bettrans14: Unsuccessfully generated data for rptDepWinlost_Trans ==> RETURN'
				RETURN
			END
		
			
		IF EXISTS (SELECT TOP 1 1 FROM bodb_Report.dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE winlostdate = @PreviousDay)
		BEGIN	
			--2.Check if the input @Winlostdate's data has not been summarized for rptDepWinlost_Main
			IF NOT EXISTS (SELECT TOP 1 1 FROM bodb_Report.dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE winlostdate = @Winlostdate)
			BEGIN
				--Insert if data do not exists 
				INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
					SELECT @Winlostdate, m.CustID
							, (m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
							   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
							   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0))--compute @Winlostdate's OpeningBalance
							, e.actualrate, m.srecommend, m.mrecommend, m.recommend, m.currency
					FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
						INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) 
						ON m.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate
						LEFT JOIN bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
						ON m.Winlostdate = t.Winlostdate AND m.CustID = t.CustID AND t.SportType = -1 AND t.PartnerID = -1 --only get attributes of rptDepWinlost]
					WHERE m.Winlostdate = @PreviousDay
				SELECT @NumberofCus = @@ROWCOUNT
			END
			ELSE
			BEGIN
				--Merge customers' @Winlostdate OpeningBalance if customers have transactions on @PreviousDay
				INSERT INTO #rptDepWinlost_Main (CustID, OpeningBalance, srecommend, mrecommend, recommend, currency)
					SELECT m.CustID
						   , (m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
							   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
							   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0))--compute @Winlostdate's OpeningBalance
						   , m.srecommend, m.mrecommend, m.recommend, m.currency
					FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
						 INNER JOIN bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
						 ON t.CustID = m.CustID AND m.Winlostdate = @PreviousDay AND t.Winlostdate = @PreviousDay AND t.SportType = -1 AND t.PartnerID = -1--only get attributes of rptDepWinlost
				
				UPDATE mt
				SET mt.actualrate = e.ActualRate
				FROM #rptDepWinlost_Main mt
					 INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) ON mt.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate	
				
				MERGE bodb_Report.dbo.rptDepWinlost_Main AS TARGET
				USING (SELECT CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency FROM #rptDepWinlost_Main)
				   AS SOURCE (CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
					ON (TARGET.CustID = SOURCE.CustID AND TARGET.Winlostdate = @Winlostdate)
				WHEN MATCHED THEN 
					 UPDATE SET TARGET.OpeningBalance = SOURCE.OpeningBalance
				WHEN NOT MATCHED THEN	
					INSERT (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
					VALUES (@Winlostdate, SOURCE.CustID, SOURCE.OpeningBalance, SOURCE.actualrate, SOURCE.srecommend, SOURCE.mrecommend, SOURCE.recommend, SOURCE.currency);
					
				SELECT @NumberofCus = @@ROWCOUNT 
				
				--Update customers' @Winlostdate OpeningBalance = @PreviousDay OpeningBalance if customers don't have transactions on @PreviousDay
				--This is for the case that winlostdate of one or some tickets (in the past) have been updated
				TRUNCATE TABLE #rptDepWinlost_Main
				INSERT INTO #rptDepWinlost_Main (CustID, OpeningBalance, srecommend, mrecommend, recommend, currency)
					SELECT m.CustID, m.OpeningBalance, m.srecommend, m.mrecommend, m.recommend, m.currency
					FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK)
					WHERE m.Winlostdate = @PreviousDay
						AND m.CustID NOT IN (SELECT CustID 
											 FROM bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
											 WHERE t.Winlostdate = @PreviousDay AND t.SportType = -1 AND t.PartnerID = -1)--only get attributes of rptDepWinlost
										 
				UPDATE m WITH (UPDLOCK, ROWLOCK)
				SET m.OpeningBalance = mt.OpeningBalance
				FROM bodb_Report.dbo.rptDepWinlost_Main m 
					INNER JOIN #rptDepWinlost_Main mt ON m.CustID = mt.CustID AND m.Winlostdate = @Winlostdate 
				WHERE m.OpeningBalance != mt.OpeningBalance
				
				--Force merge join query
				DECLARE @n INT = 2147483647
				
				IF EXISTS (SELECT TOP (@n) 1 
						   FROM #rptDepWinlost_Main mt
						   LEFT JOIN  bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
								ON mt.CustID = m.CustID AND m.Winlostdate = @Winlostdate
						   WHERE m.CustID IS NULL
						   )							      
						   
				BEGIN
					UPDATE mt
					SET mt.actualrate = e.ActualRate
					FROM #rptDepWinlost_Main mt
						 INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) ON mt.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate
								 
					INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
						SELECT @Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency
						FROM #rptDepWinlost_Main 
						WHERE CustID NOT IN (SELECT CustID FROM bodb_Report.dbo.rptDepWinlost_Main WHERE Winlostdate = @Winlostdate)
				END
				
			END
			
			--Delete redundant data
			DELETE FROM bodb_Report.dbo.rptDepWinlost_Main WITH (ROWLOCK, UPDLOCK) 
			WHERE OpeningBalance = 0 AND Winlostdate = @Winlostdate
			
			--3.Insert customers that are missing from rptDepWinlost_Main compared with rptDepwinlost_Trans (first transaction)
			TRUNCATE TABLE #rptDepWinlost_Main
			INSERT INTO #rptDepWinlost_Main (CustID)
			SELECT CustID
			FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (NOLOCK) 
			WHERE Winlostdate = @Winlostdate
				  AND SportType = -1 AND PartnerID = -1 --only get attributes of rptDepWinlost
				  AND CustID NOT IN (SELECT CustID FROM bodb_Report.dbo.rptDepWinlost_Main WITH (NOLOCK) WHERE Winlostdate = @Winlostdate)
			
			IF EXISTS (SELECT TOP 1 1 FROM #rptDepWinlost_Main)
			UPDATE mt
			SET mt.OpeningBalance = tmp.OpeningBalance
			FROM #rptDepWinlost_Main mt
				INNER JOIN 
				(SELECT m.CustID
						, m.OpeningBalance + ISNULL(t.Deposit,0) + ISNULL(t.Aff2MemTransfer,0) - ISNULL(t.Withdrawal,0) + ISNULL(t.Bonus,0) 
							   + ISNULL(t.Adjustment,0) - ISNULL(t.Outstanding,0) + ISNULL(t.Winloss,0) + ISNULL(t.playercomm,0) + ISNULL(t.Transfer3rd,0) 
							   + ISNULL(t.Transfer3rdOthers,0) - ISNULL(t.Comm_BetTrade_Full,0) AS OpeningBalance
				 FROM bodb_Report.dbo.rptDepWinlost_Main m WITH (NOLOCK) 
					  INNER JOIN bodb_Report.dbo.rptDepWinlost_Trans t WITH (NOLOCK) 
					  ON t.CustID = m.CustID AND m.Winlostdate = @PreviousDay AND t.Winlostdate = @PreviousDay AND t.SportType = -1 AND t.PartnerID = -1) tmp 
				ON mt.CustID = tmp.CustID
				
			UPDATE mt
			SET mt.srecommend = c.srecommend
				, mt.mrecommend = c.mrecommend
				, mt.recommend = c.recommend
				, mt.currency = CASE 
									WHEN c.recommend IN (14373731, 14373733) AND @Winlostdate < '20141128' THEN 13
									WHEN c.recommend IN (14373731, 14373733) AND @Winlostdate >= '20141128' THEN 66 
									ELSE c.currency 
								END
			FROM #rptDepWinlost_Main mt
				 INNER JOIN dbo.custInfo c WITH (NOLOCK) ON mt.CustID = c.custid AND c.roleid = 1
				 
			INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
				SELECT @Winlostdate, mt.CustID, mt.OpeningBalance, e.ActualRate, mt.srecommend, mt.mrecommend, mt.recommend, mt.currency
				FROM #rptDepWinlost_Main mt	 
				INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) ON mt.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate 
				
			SELECT @NumberofCus = @NumberofCus + @@ROWCOUNT
			
			SET @isSuccessful = 1	
		END
		ELSE --
		BEGIN
			INSERT INTO #rptDepWinlost_Main (CustID, OpeningBalance, srecommend, mrecommend, recommend, currency)
				SELECT b.CustID
					   , SUM(CASE @Winlostdate WHEN @BalanceUpDay 
					    		THEN CASE WHEN bettype = 20000 THEN winlost - actual_stake + playercomm ELSE 0 END 
								ELSE CASE WHEN winlostdate < @Winlostdate THEN winlost - actual_stake + playercomm ELSE 0 END 
							  END)
					   , b.srecommend, b.mrecommend, b.recommend, 
						CASE 
							WHEN b.recommend IN (14373731, 14373733) AND @Winlostdate < '20141128' THEN 13
							WHEN b.recommend IN (14373731, 14373733) AND @Winlostdate >= '20141128' THEN 66 
						ELSE b.currency 
						END
				FROM dbo.bettrans b WITH (NOLOCK) 
					INNER JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON b.srecommend = d.custid
					INNER JOIN dbo.CustInfo c WITH (NOLOCK) ON b.custid = c.custid
				WHERE b.winlostdate <= @Winlostdate
					  AND b.matchid >= 0
					  AND c.roleid = 1
				GROUP BY b.custid, b.srecommend, b.mrecommend, b.recommend, 
						CASE 
							WHEN b.recommend IN (14373731, 14373733) AND @Winlostdate < '20141128' THEN 13
							WHEN b.recommend IN (14373731, 14373733) AND @Winlostdate >= '20141128' THEN 66 
						ELSE b.currency
						END
				OPTION (RECOMPILE, MAXDOP 8)
				
				DELETE FROM #rptDepWinlost_Main
				WHERE CustID NOT IN (SELECT CustID FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (NOLOCK) WHERE Winlostdate = @Winlostdate)
					AND OpeningBalance = 0
				
				DELETE FROM bodb_Report.dbo.rptDepWinlost_Main WITH (UPDLOCK, ROWLOCK)
				WHERE Winlostdate = @Winlostdate
				
				INSERT INTO bodb_Report.dbo.rptDepWinlost_Main (Winlostdate, CustID, OpeningBalance, actualrate, srecommend, mrecommend, recommend, currency)
				SELECT @Winlostdate, mt.CustID, mt.OpeningBalance, e.ActualRate, mt.srecommend, mt.mrecommend, mt.recommend, mt.currency
				FROM #rptDepWinlost_Main mt	 
				INNER JOIN dbo.ExchangeDailyOanda e WITH (NOLOCK) ON mt.currency = e.ExchangeId AND e.ExchangeDate = @Winlostdate 
				
				SELECT @NumberofCus = @@ROWCOUNT
				
				SET @isSuccessful = 1
		END
	END TRY
	BEGIN CATCH
		PRINT 'EXEC GEN_HourlySummaryDepData_Bettrans14, Winlostdate = ' + CONVERT(VARCHAR(20),@Winlostdate,112) + ', ErrMsg: ' + ERROR_MESSAGE()
		SET @isSuccessful = 0
	END CATCH
	
	DROP TABLE #rptDepWinlost_Main
END

