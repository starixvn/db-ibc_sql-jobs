
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GEN_rptBetting_ColossusBets    Script Date: 11/9/2016 4:18:55 PM ******/

 
CREATE PROCEDURE [dbo].[GEN_rptBetting_ColossusBets] 
	@date SMALLDATETIME = NULL
	,@date2 SMALLDATETIME = NULL
AS
/*   
 Created:  20160928@Jim
 DB: DBLIC.bodb_LicenseeReport   
 Task: Gen data from bettrans before Move bets [RedminID : #63785]
 Original:   
 Revisions:   
 - 20161101@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
*/
BEGIN
	DECLARE @tmpRawData AS TABLE (
			rptDate datetime
			, CustID int
			, Bettype smallint
			, CurrencyID int
			, StatusID smallint
			, TotalTrans int
			, Turnover money
			, WinningPrize money
			, CashOutAmt money
			, CashInAmt money
			, CommAmt money
			, GrandAmt money
			, CashInShare money
			)
	DECLARE @tmpGrandAmt AS TABLE (
			refno BIGINT
			,rptDate DATETIME
			,CustID INT
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
			, STATUS NVARCHAR(20)
			, statusID INT
			, GrandAmt MONEY
			)
			
	INSERT INTO @tmpGrandAmt (
		refno 
		, rptDate
		, CustID
		, GrandAmt
		)
	SELECT 
		  refno	
		 ,winlostdate
		 ,CustID
		, SUM(WinAmount) AS GrandAmt
	FROM DBACC.bodb02.dbo.PayoutTrans p WITH (NOLOCK)
	WHERE productId = 204
		AND p.winlostdate BETWEEN @date
			AND @date2
	GROUP BY CustID
			,winlostdate
			,refno	
	INSERT INTO @tmpBettrans (
			custid
			,refno
			, winlostdate
			, Currency
			, TurnOver
			, TotalTrans
			, Winlost
			, STATUS
			, statusID
			, GrandAmt
			)
		SELECT b.CustId 
			, b.refno
			, b.winlostdate
			, b.Currency
			, SUM(ABS(b.Stake)) TurnOver
			, COUNT(DISTINCT b.refno) TotalTrans
			, b.Winlost
			, b.STATUS
			, b.statusID
			, SUM(a.GrandAmt) AS GrandAmt
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.LicenseeCust t WITH (NOLOCK)
			ON b.recommend = t.CustID
				AND b.Currency = t.Currency
		LEFT JOIN @tmpGrandAmt a
			ON b.CustID = a.CustID
				AND b.winlostdate = a.rptDate
				AND b.transid = a.refno
		WHERE b.bettype = 18000
			AND b.winlostdate BETWEEN @date
			AND @date2
			AND b.StatusID IN (111, 112, 113)
		GROUP BY b.CustId 
			, b.refno
			, b.winlostdate
			, b.Currency
			, b.Winlost
			, b.STATUS
			, b.statusID
	INSERT INTO @tmpRawData (
				rptDate,
				CustID,
				Bettype,
				CurrencyID,
				StatusID,
				TotalTrans,
				Turnover,
				WinningPrize,
				CashOutAmt,
				CashInAmt,
				CashInShare,
				CommAmt,
				GrandAmt
				)			
	SELECT		b.winlostdate rptDate
				,b.CustID
				,18000 bettype
				,b.Currency CurrencyID
				,b.statusID
				, COUNT(DISTINCT b.refno) TotalTrans
				, 0 TurnOver
				, SUM(CASE 
						WHEN b.winlost = 0
							THEN 0
						ELSE CASE 
								WHEN bm.bettype IN (
										18004
										, 18005
										, 18006
										)
									AND b.STATUS = 'WON'			
									THEN bm.Winlost - bm.stake
								ELSE 0
								END
						END) AS WinningPrize
				, SUM(CASE 
						WHEN b.winlost = 0
							THEN 0
						ELSE CASE 
								WHEN bm.bettype = 18002
									AND b.STATUS = 'WON'		
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
			INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK)
				ON b.refno = bm.refno
			WHERE  bm.bettype BETWEEN 18001
				AND 18006
			GROUP BY b.winlostdate  
				,b.CustID
				,b.Currency  
				,b.statusID
	;WITH cte_TO
		AS (
			SELECT Currency
				, winlostdate
				, custID
				, SUM(TurnOver) TurnOver
				, SUM(GrandAmt) GrandAmt
			FROM @tmpBettrans
			GROUP BY Currency
				, winlostdate
				, custID
			)
		UPDATE d
		SET TurnOver = s.TurnOver
			,GrandAmt = s.GrandAmt
		FROM @tmpRawData d
		INNER JOIN cte_TO s
			ON d.CurrencyID = s.Currency
				AND d.rptDate = s.Winlostdate 
				AND d.CustID = s.CustID
	
	DELETE dbo.rpt_BettingColossusBets
	WHERE rptDate BETWEEN @date
						AND @date2

	INSERT INTO dbo.rpt_BettingColossusBets
				(
				rptDate,
				CustID,
				Bettype,
				CurrencyID,
				StatusID,
				TotalTrans,
				Turnover,
				WinningPrize,
				CashOutAmt,
				CashInAmt,
				CashInShare,
				CommAmt,
				GrandAmt
				)
				
	SELECT rptDate,
			CustID,
			Bettype,
			CurrencyID,
			StatusID,
			SUM(TotalTrans),
			SUM(Turnover),
			SUM(WinningPrize),
			SUM(CashOutAmt),
			SUM(CashInAmt),
			SUM(CashInShare),
			SUM(CommAmt),
			SUM(GrandAmt)
	FROM @tmpRawData			
	GROUP BY rptDate,
			CustID,
			Bettype,
			CurrencyID,
			StatusID
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
