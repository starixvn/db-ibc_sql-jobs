USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_rptBettingColossusBets_CheckData] @WinlostDate SMALLDATETIME
AS
/*   
 Created:  20160928@Jim
 DB: DBLIC/bodb_LicenseeReport  
 Task: Check & correct data for rpt_BettingColossusBets [RedminID : #63785]
 Original:   
 Revisions:   
 - 20161101@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
 - 20161121@Sophia: Correct CashOutAmount,WinPrizeAmount value [RedmineID : #67473] 
*/
BEGIN
	DECLARE @S_TotalTrans INT
		, @D_TotalTrans INT
		, @S_Turnover MONEY
		, @D_Turnover MONEY
		, @S_WinningPrize MONEY
		, @D_WinningPrize MONEY
		, @S_CashOutAmt MONEY
		, @D_CashOutAmt MONEY
		, @S_CashInAmt MONEY
		, @D_CashInAmt MONEY
		, @S_CashInShare MONEY
		, @D_CashInShare MONEY
		, @S_CommAmt MONEY
		, @D_CommAmt MONEY
		, @S_GrandAmt MONEY
		, @D_GrandAmt MONEY
	
	DECLARE @tmpRawData AS TABLE (
		rptDate DATETIME
		, TotalTrans INT
		, Turnover MONEY
		, WinningPrize MONEY
		, CashOutAmt MONEY
		, CashInAmt MONEY
		, CommAmt MONEY
		, GrandAmt MONEY
		, CashInShare MONEY
		)
	DECLARE @tmpGrandAmt AS TABLE (
		rptDate DATETIME
		, CustID INT
		, GrandAmt MONEY
		)
	DECLARE @tmpBettrans AS TABLE (
		custid INT
		, refno BIGINT
		, winlostdate DATETIME
		, Currency INT
		, TurnOver MONEY
		, TotalTrans INT
		, Winlost MONEY
		, Actual_Stake MONEY
		, STATUS NVARCHAR(20)
		, GrandAmt MONEY
		)
	------------------------------------
	INSERT INTO @tmpGrandAmt (
		rptDate
		, CustID
		, GrandAmt
		)
	SELECT winlostdate
		, CustID
		, SUM(WinAmount) AS GrandAmt
	FROM DBACC.bodb02.dbo.PayoutTrans p WITH (NOLOCK)
	WHERE productId = 204
		AND p.winlostdate = @WinlostDate
	GROUP BY CustID
		, winlostdate

	INSERT INTO @tmpBettrans (
		custid
		, refno
		, winlostdate
		, Currency
		, TurnOver
		, TotalTrans
		, Winlost
		, Actual_Stake
		, STATUS
		, GrandAmt
		)
	SELECT b.CustId
		, b.refno
		, b.winlostdate
		, b.Currency
		, SUM(ABS(b.Stake)) TurnOver
		, COUNT(DISTINCT b.refno) TotalTrans
		, b.Winlost
		, b.Actual_Stake
		, b.STATUS
		, SUM(a.GrandAmt) AS GrandAmt
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
	INNER JOIN bodb_licensee.dbo.LicenseeCust t
		ON b.recommend = t.CustID
			AND b.Currency = t.Currency
	LEFT JOIN @tmpGrandAmt a
		ON b.CustID = a.CustID
			AND b.winlostdate = a.rptDate
	WHERE b.bettype = 18000
		AND b.winlostdate = @WinlostDate
	GROUP BY b.CustId
		, b.refno
		, b.winlostdate
		, b.Currency
		, b.Winlost
		, b.Actual_Stake
		, b.STATUS

	INSERT INTO @tmpRawData (
		rptDate
		, TotalTrans
		, Turnover
		, WinningPrize
		, CashOutAmt
		, CashInAmt
		, CashInShare
		, CommAmt
		, GrandAmt
		)
	SELECT b.winlostdate rptDate
		, COUNT(DISTINCT b.refno) TotalTrans
		, 0 TurnOver
		, SUM(CASE 
				WHEN (b.winlost - b.actual_stake ) < 0 AND b.STATUS = 'WON'
					THEN 0
				ELSE CASE 
						WHEN bm.bettype IN (
								18004
								, 18005
								, 18006
								)							
							THEN bm.Winlost - bm.stake
						ELSE 0
						END
				END) AS WinningPrize
		, SUM(CASE 
				WHEN (b.winlost - b.actual_stake ) < 0 AND b.STATUS = 'WON'
					THEN 0
				ELSE CASE 
						WHEN bm.bettype = 18002
							THEN bm.winlost - bm.stake
						ELSE 0
						END
				END) AS CashOutAmt
		, SUM(CASE 
				WHEN bm.bettype = 18002
					THEN bm.oddsspread
				ELSE 0
				END) AS CashInAmt
		, SUM(CASE 
				WHEN bm.bettype = 18002
					THEN bm.acomm
				ELSE 0
				END) AS CashInShare
		, SUM(CASE 
				WHEN bm.bettype = 18001
					THEN bm.acomm
				ELSE 0
				END) CommAmt
		, 0 AS GrandAmt
	FROM @tmpBettrans b
	INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK)
		ON b.refno = bm.refno
	WHERE bm.bettype BETWEEN 18001
			AND 18006
	GROUP BY b.winlostdate 

	;WITH cte_TO
	AS (
		SELECT 
			winlostdate
			, SUM(TurnOver) TurnOver
			, SUM(GrandAmt) GrandAmt
		FROM @tmpBettrans
		GROUP BY  
			winlostdate
		)
	UPDATE d
	SET TurnOver = s.TurnOver
		, GrandAmt = s.GrandAmt
	FROM @tmpRawData d
	INNER JOIN cte_TO s
		ON  d.rptDate = s.Winlostdate

	SELECT @S_TotalTrans = SUM(TotalTrans)
		, @S_Turnover = SUM(Turnover)
		, @S_WinningPrize = SUM(WinningPrize)
		, @S_CashOutAmt = SUM(CashOutAmt)
		, @S_CashInAmt = SUM(CashInAmt)
		, @S_CashInShare = SUM(CashInShare)
		, @S_CommAmt = SUM(CommAmt)
		, @S_GrandAmt = SUM(GrandAmt)
	FROM @tmpRawData
	WHERE rptDate = @Winlostdate

	SELECT @D_TotalTrans = SUM(TotalTrans)
		, @D_Turnover = SUM(Turnover)
		, @D_WinningPrize = SUM(WinningPrize)
		, @D_CashOutAmt = SUM(CashOutAmt)
		, @D_CashInAmt = SUM(CashInAmt)
		, @D_CashInShare = SUM(CashInShare)
		, @D_CommAmt = SUM(CommAmt)
		, @D_GrandAmt = SUM(GrandAmt)
	FROM dbo.rpt_BettingColossusBets WITH (NOLOCK)
	WHERE rptDate = @Winlostdate
	------------------------------------
	--if diff then generate data again
	IF ISNULL(@D_TotalTrans, 0) <> ISNULL(@S_TotalTrans, 0)
		OR ISNULL(@D_Turnover, 0) <> ISNULL(@S_Turnover, 0)
		OR ISNULL(@D_WinningPrize, 0) <> ISNULL(@S_WinningPrize, 0)
		OR ISNULL(@D_CashOutAmt, 0) <> ISNULL(@S_CashOutAmt, 0)
		OR ISNULL(@D_CashInAmt, 0) <> ISNULL(@S_CashInAmt, 0)
		OR ISNULL(@D_CashInShare, 0) <> ISNULL(@S_CashInShare, 0)
		OR ISNULL(@D_CommAmt, 0) <> ISNULL(@S_CommAmt, 0)
		OR ISNULL(@D_GrandAmt, 0) <> ISNULL(@S_GrandAmt, 0)
	BEGIN
		PRINT 'Re-generate data for rpt_BettingColossusBets on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
								EXEC dbo.GEN_rptBetting_ColossusBets14 @date  = @WinlostDate, @date2 = @WinlostDate
		RETURN
	END
	
END
 