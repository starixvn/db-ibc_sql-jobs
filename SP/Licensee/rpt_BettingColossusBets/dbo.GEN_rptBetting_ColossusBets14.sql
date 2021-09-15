/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBetting_ColossusBets14] 
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
	 - 20161121@Sophia: Correct fomular CashOutAmount,WinPrizeAmount value [RedmineID : #67473]
	 - 20180305@Harper: Implement CB free play ticket [RedmineID: #90768]
	 - 20210816@Sophia: add DBBAL [Redmine: #154300]

 EXEC GEN_rptBetting_ColossusBets14 '2018-02-01', '2018-03-08'
*/
BEGIN
	DECLARE @tmpRawData AS TABLE (
			rptDate			DATETIME
			, CustID		INT
			, Bettype		SMALLINT
			, CurrencyID	INT
            , TicketType	TINYINT
			, StatusID		SMALLINT
			, TotalTrans	INT
			, Turnover		MONEY
			, WinningPrize	MONEY
			, CashOutAmt	MONEY
			, CashInAmt		MONEY
			, CommAmt		MONEY
			, GrandAmt		MONEY
			, CashInShare	MONEY
			)

	DECLARE @tmpGrandAmt AS TABLE (
			refno		BIGINT
			,rptDate	DATETIME
			,CustID		INT
			, GrandAmt	MONEY
			)

	DECLARE @tmpBettrans AS TABLE (
			custid			INT
			, refno			BIGINT
			, winlostdate	DATETIME
			, Currency		INT
			, TicketType	TINYINT
			, TurnOver		MONEY
			, TotalTrans	INT
			, Winlost		MONEY
			, actual_stake	MONEY
			, STATUS		NVARCHAR(20)
			, statusID		INT
			, GrandAmt		MONEY
			)
			
	INSERT INTO @tmpGrandAmt (
		Refno
		, rptDate
		, CustID
		, GrandAmt
		)
	SELECT 
		 Refno	
		 ,winlostdate
		 ,CustID
		 ,SUM(WinAmount) AS GrandAmt
	FROM DBACC.bodb02.dbo.PayoutTrans p WITH (NOLOCK)
	WHERE productId = 204
		AND p.winlostdate BETWEEN @date	AND @date2
	GROUP BY CustID
			,winlostdate
			,Refno

	INSERT INTO @tmpBettrans (
			custid
			,refno
			, winlostdate
			, Currency
			, TicketType
			, TurnOver
			, TotalTrans
			, Winlost
			, Actual_stake
			, STATUS
			, statusID
			, GrandAmt
			)
		SELECT b.CustId 
			, b.refno
			, b.winlostdate
			, b.Currency
			, ISNULL(b.currency2, 0) -- NULL is Money Play
			, SUM(ABS(b.Stake)) TurnOver
			, COUNT(DISTINCT b.refno) TotalTrans
			, b.Winlost
			, b.Actual_stake
			, b.STATUS
			, b.StatusID
			, SUM(a.GrandAmt) AS GrandAmt
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.LicenseeCust t WITH (NOLOCK)
			ON b.recommend = t.CustID
				AND b.Currency = t.Currency
		LEFT JOIN @tmpGrandAmt a
			ON b.CustID = a.CustID
				AND b.winlostdate = a.rptDate
				AND b.transID = a.Refno
		WHERE b.bettype = 18000
			AND b.winlostdate BETWEEN @date
			AND @date2
			AND b.StatusID IN (111, 112, 113)
		GROUP BY b.CustId 
			, b.refno
			, b.winlostdate
			, b.Currency
			, ISNULL(b.currency2, 0) -- NULL is Money Play
			, b.Winlost
			, b.Actual_stake
			, b.STATUS
			, b.StatusID

	INSERT INTO @tmpRawData (
				rptDate,
				CustID,
				Bettype,
				CurrencyID,
				TicketType,
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
				,b.TicketType
				,b.statusID
				, COUNT(DISTINCT b.refno) TotalTrans
				, 0 TurnOver
				, SUM(CASE 
						WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
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
						WHEN (b.winlost - b.actual_stake ) < 0 AND b.statusID = 112 
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
			WHERE  bm.bettype BETWEEN 18001
				AND 18006
			GROUP BY b.winlostdate  
				, b.CustID
				, b.Currency  
				, b.TicketType
				, b.statusID

	;WITH cte_TO
		AS (
			SELECT Currency
				, TicketType
				, winlostdate
				, custid
				, StatusID
				, SUM(TurnOver) TurnOver
				, SUM(GrandAmt) GrandAmt
			FROM @tmpBettrans
			GROUP BY Currency
				, TicketType
				, winlostdate
				, custid
				, StatusID
			)
		UPDATE d
		SET TurnOver = s.TurnOver
			,GrandAmt = s.GrandAmt
		FROM @tmpRawData d
		INNER JOIN cte_TO s
			ON d.CurrencyID = s.Currency
				AND d.TicketType = s.TicketType
				AND d.rptDate = s.Winlostdate 
				AND d.custId = s.CustID
				AND d.StatusID = s.StatusID
	
	DELETE dbo.rpt_BettingColossusBets
	WHERE rptDate BETWEEN @date AND @date2

	INSERT INTO dbo.rpt_BettingColossusBets
				(
				rptDate,
				CustID,
				Bettype,
				CurrencyID,
				TicketType,
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
			TicketType,
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
			TicketType,
			StatusID
END
GO
