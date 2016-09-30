CREATE PROCEDURE [dbo].[GEN_rptBetting_ColossusBets] 
	@date SMALLDATETIME = NULL
	,@date2 SMALLDATETIME = NULL
AS
/*   
 Created:  20160928@Jim
 DB: DBLIC.bodb_licensee  
 Task: Gen data from bettrans before Move bets [RedminID : #63785]
 Original:   
 Revisions:   
    
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
			rptDate DATETIME
			,CustID INT
			, GrandAmt MONEY
			)
	
	INSERT INTO @tmpGrandAmt (
		rptDate
		, CustID
		, GrandAmt
		)
	SELECT 
		 winlostdate
		 ,CustID
		, SUM(WinAmount) AS GrandAmt
	FROM DBACC.bodb02.dbo.PayoutTrans p WITH (NOLOCK)
	WHERE productId = 204
		AND p.winlostdate BETWEEN @date
			AND @date2
	GROUP BY CustID
			,winlostdate
	
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
				,bm.bettype
				,b.Currency CurrencyID
				,bm.statusID
				, COUNT(DISTINCT b.refno) TotalTrans
				, SUM(ABS(b.Stake)) TurnOver
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
			FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK)
				ON b.refno = bm.refno
			INNER JOIN dbo.LicenseeCust lc WITH (NOLOCK) 
				ON b.Recommend = lc.CustID
			WHERE b.bettype = 18000
				AND b.winlostdate BETWEEN @date
							AND @date2
			GROUP BY b.winlostdate  
				,b.CustID
				,bm.bettype
				,b.Currency  
				,bm.statusID
	UPDATE d
	SET GrandAmt = s.GrandAmt
	FROM @tmpRawData d
	INNER JOIN @tmpGrandAmt s
		ON  s.rptDate = d.rptDate
			AND s.CustID = d.CustID
	
	DELETE bodb_licenseereport.dbo.rpt_BettingColossusBets
	WHERE rptDate BETWEEN @date
						AND @date2

	INSERT INTO bodb_licenseereport.dbo.rpt_BettingColossusBets
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
