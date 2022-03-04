/*<info serverAlias="DBBAL-bodb_LicenseeReport" executers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MonthlyOldData_Cleanup]  
AS  
/*  
	Created: 20220303@Evan
	Task: Remove monthly data on DBBAL -[169074]
	DB: DBBAL-bodb_LicenseeReport

	Revisions:	
	- 20220303@Evan: Initialize SPs [RedmineID : #169074]
*/  
 
BEGIN  

	SET NOCOUNT ON

	DECLARE @CutOffDate SMALLDATETIME 

	-- Keep data of 3 months
	SELECT @CutOffDate =  DATEADD(MONTH, -3,DATEADD(DAY,-DAY(GETDATE())+1, CAST(GETDATE() AS DATE)))
	DECLARE @BatchSize INT = 5000
	DECLARE @Batch TABLE (recommend INT PRIMARY KEY)


	CREATE TABLE #TmpRecommend(
		recommend INT 
	)

	INSERT INTO #TmpRecommend(recommend)
	SELECT DISTINCT recommend 
		FROM dbo.rptCustomerTurnover WITH(NOLOCK) 
		WHERE winlostdate < @CutOffDate

	WHILE EXISTS(SELECT 1 FROM #TmpRecommend)
	BEGIN 

		DELETE TOP(100) d
		OUTPUT DELETEd.recommend INTO @Batch
		FROM #TmpRecommend d

		WHILE 1 = 1
		BEGIN
			DELETE TOP(@BatchSize) rpt
			FROM dbo.rptCustomerTurnover rpt
			INNER JOIN @Batch b on b.recommend = rpt.recommend
			WHERE rpt.winlostdate < @CutOffDate

			IF @@ROWCOUNT < @BatchSize
				BREAK
		END

		DELETE FROM @Batch

	END


	INSERT INTO #TmpRecommend(recommend)
	SELECT DISTINCT recommend 
		FROM dbo.rptCasinoTurnover WITH(NOLOCK) 
		WHERE WinlostDate < @CutOffDate

	WHILE EXISTS(SELECT 1 FROM #TmpRecommend)
	BEGIN 

		DELETE TOP(100) d
		OUTPUT DELETEd.recommend INTO @Batch
		FROM #TmpRecommend d

		WHILE 1 = 1
		BEGIN
			DELETE TOP(@BatchSize) rpt
			FROM dbo.rptCasinoTurnover rpt
			INNER JOIN @Batch b on b.recommend = rpt.recommend
			WHERE rpt.WinlostDate < @CutOffDate

			IF @@ROWCOUNT < @BatchSize
				BREAK
		END

		DELETE FROM @Batch

	END

	DROP TABLE #TmpRecommend


	CREATE TABLE #TempBettingParlay(
		RecordID BIGINT PRIMARY KEY,
		Isfinished BIT
	)

	CREATE TABLE #BettingParlay_Batch(
		RecordID BIGINT PRIMARY KEY
	)

	INSERT INTO #TempBettingParlay (RecordID)
	SELECT RecordID 
		FROM dbo.rpt_BettingParlay WITH (NOLOCK) 
		WHERE rptDate < @CutOffDate

	WHILE 1 = 1
	BEGIN

		UPDATE TOP (@BatchSize) R
			SET Isfinished = 1	
			OUTPUT DELETED.RecordID
			INTO #BettingParlay_Batch (RecordID)		
		FROM #TempBettingParlay r
		WHERE r.Isfinished IS NULL
	
		IF @@ROWCOUNT = 0
			BREAK

		DELETE s 
		FROM dbo.rpt_BettingParlay s 
			INNER JOIN #BettingParlay_Batch t ON t.RecordID = s.RecordID

		TRUNCATE TABLE #BettingParlay_Batch

	END

	DROP TABLE #TempBettingParlay
	DROP TABLE #BettingParlay_Batch


	CREATE TABLE #TempMatch(
		matchid BIGINT PRIMARY KEY,
		Isfinished BIT
	)

	CREATE TABLE #Match_Batch(
		matchid BIGINT PRIMARY KEY
	)

	INSERT INTO #TempMatch (matchid)
	SELECT matchid 
		FROM dbo.match WITH (NOLOCK) 
		WHERE eventdate < @CutOffDate

	WHILE 1 = 1
	BEGIN

		UPDATE TOP (@BatchSize) R
			SET Isfinished = 1	
			OUTPUT DELETED.matchid
			INTO #Match_Batch (matchid)		
		FROM #TempMatch r
		WHERE r.Isfinished IS NULL
	
		IF @@ROWCOUNT = 0
			BREAK

		DELETE s 
		FROM dbo.match s 
			INNER JOIN #Match_Batch t ON t.matchid = s.matchid

		TRUNCATE TABLE #Match_Batch

	END

	DROP TABLE #TempMatch
	DROP TABLE #Match_Batch


	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptCustomerMatch 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptLicWinloss2 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptLicWinlossGMT
		WHERE RptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN
	
		DELETE TOP(@BatchSize) 
		FROM dbo.rptWinlostbyLeague 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_Betting 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.bettrans 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.DataCheckingLog 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_BettingByProduct 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_ThirdPartyWL_ExtraGMT 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_Betting_BA 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK
	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptLicCashoutSummary 
		WHERE Winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_BettingBySport 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_BettingColossusBets 
		WHERE rptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.outright 
		WHERE eventdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rpt_CustomerWL_ExtraGMT 
		WHERE RptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptDepWinlost_ThirdParty 
		WHERE Winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptDepWinlost_ThirdParty_Performance
		WHERE Winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptLicIPBetting 
		WHERE winlostdate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END

	WHILE 1 = 1
	BEGIN

		DELETE TOP(@BatchSize) 
		FROM dbo.rptLicPromotion 
		WHERE RptDate < @CutOffDate

		IF @@ROWCOUNT < @BatchSize
			BREAK

	END
END
GO
