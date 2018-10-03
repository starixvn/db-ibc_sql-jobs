/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO


ALTER PROCEDURE [dbo].[Task_rptLicCashoutSummary_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rptLicCashoutSummary
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revision:
		-20181003@Bruce: LA - Should not include refund ticket for Cash Out Tickets [Redmine: #102578]
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source 
	(
		CustID				INT,
		Currency			INT,
		recommend			INT,
		TicketPayout		MONEY,
		CashoutComm			MONEY,
		CashoutAmount		MONEY,
		BuyBackAmt			MONEY,
		BABuyBackAmt		MONEY,
		NumOfCashoutTicket	INT,
		NumOfCashoutTrans	INT
	);

	CREATE TABLE #Target 
	(
		CustID				INT,
		Currency			INT,
		recommend			INT,
		TicketPayout		MONEY,
		CashoutComm			MONEY,
		CashoutAmount		MONEY,
		BuyBackAmt			MONEY,
		BABuyBackAmt		MONEY,
		NumOfCashoutTicket	INT,
		NumOfCashoutTrans	INT
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	CREATE TABLE #Bettype (Bettype INT, ProductID INT);

	INSERT INTO #Bettype(Bettype, ProductID)
	SELECT Bettype, ProductID 
	FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, 'CO');

	CREATE TABLE #CashoutCust (CustId INT PRIMARY KEY);

	INSERT INTO #CashoutCust(CustId)
	SELECT CustId 
	FROM bodb02.dbo.f_GetCashoutCustList('ALL', 14);

	INSERT INTO #Source
	(
			CustID,		
			Currency,
			recommend,
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,			
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT	b.custid, b.currency,
			b.recommend,
			ISNULL(SUM(ISNULL(po.winlost, 0)), 0),
			ISNULL(SUM(ISNULL(comm.Comm, 0)), 0),
			ISNULL(SUM(CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1003 THEN b.winlost ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1004 THEN b.winlost ELSE 0 END), 0),
			0,
			ISNULL(SUM(CASE WHEN b.bettype = 911 THEN 1 ELSE 0 END), 0)
	FROM dbo.bettrans b WITH (NOLOCK)
		LEFT JOIN (
					SELECT b2.refno, SUM(b2.winlost) AS winlost
					FROM dbo.bettrans b2 WITH (NOLOCK)
						INNER JOIN #CashoutCust ctc ON b2.CustId = ctc.CustId
					WHERE b2.bettype NOT IN (SELECT bettype FROM #Bettype WHERE ProductID = 25)						
					GROUP BY b2.refno
				) po ON po.refno = b.transid
		LEFT JOIN ( 
					SELECT b2.refno, SUM(b2.awinlost) AS Comm
					FROM dbo.bettrans b2 WITH (NOLOCK)						
					WHERE b2.bettype = 913						
					GROUP BY b2.refno
				) comm ON comm.refno = b.transid
		INNER JOIN #Bettype bt ON b.bettype = bt.Bettype		
		INNER JOIN bodb02.dbo.customer WITH (NOLOCK) ON b.custid = customer.custid AND customer.roleid = 1
	WHERE statusid IN (111, 112, 113)	
		AND NOT EXISTS (SELECT 1 FROM #CashoutCust co WHERE co.CustId = b.CustID)
	GROUP BY b.CustID,		
		b.Currency,
		b.recommend;

	SET @S_Count = @@ROWCOUNT;

	WITH cte AS (
			SELECT b.custid, b.currency, COUNT (*) AS numOfTicket
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE betdaqid = 0 
				AND b.bettype <> 911 
				AND CAST(ExtraInfo AS XML).exist('/p25/@s') = 1
				AND b.statusid IN (111, 112, 113)
			GROUP BY b.custid, b.currency
	)
	UPDATE b
	SET b.NumOfCashoutTicket = ISNULL(cte.numOfTicket, 0)
	FROM #Source b
		INNER JOIN cte ON b.Currency = cte.currency AND b.CustID = cte.custid;

	INSERT INTO #Target
	(
			CustID,		
			Currency,
			recommend,	
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,	
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT	CustID,		
			Currency,
			Recommend,
			ISNULL(SUM(TicketPayout), 0),
			ISNULL(SUM(CashoutComm), 0),
			ISNULL(SUM(CashoutAmount), 0),
			ISNULL(SUM(BuyBackAmt), 0),	
			ISNULL(SUM(BABuyBackAmt), 0),		
			ISNULL(SUM(NumOfCashoutTicket), 0),
			ISNULL(SUM(NumOfCashoutTrans), 0)
	FROM dbo.rptLicCashoutSummary WITH(NOLOCK)
	WHERE Winlostdate = @WinlostDate
		AND RoleID = 1
	GROUP BY CustID, Currency, Recommend;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	'staging bettrans', 1, Currency, SUM(CashoutAmount), SUM(BuyBackAmt + BABuyBackAmt), SUM(NumOfCashoutTicket),
			(
				SELECT SUM(TicketPayout) AS TicketPayout, SUM(CashoutComm) AS COComm, SUM(NumOfCashoutTrans) AS COTransCnt
				FROM #Source s1
				WHERE s1.Currency = s.Currency
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t 
		WHERE s.CustID = t.CustID AND s.Currency = t.Currency AND s.recommend = t.recommend
			AND s.TicketPayout = t.TicketPayout AND s.CashoutComm = t.CashoutComm AND s.CashoutAmount = t.CashoutAmount 
			AND s.BuyBackAmt = t.BuyBackAmt AND s.BABuyBackAmt = t.BABuyBackAmt AND s.NumOfCashoutTrans = t.NumOfCashoutTrans
			AND s.NumOfCashoutTicket = t.NumOfCashoutTicket)
	GROUP BY Currency		
	
	UNION ALL
	
	SELECT 'rptLicCashoutSummary', 0, Currency, SUM(CashoutAmount), SUM(BuyBackAmt + BABuyBackAmt), SUM(NumOfCashoutTicket),
			(
				SELECT SUM(TicketPayout) AS TicketPayout, SUM(CashoutComm) AS COComm, SUM(NumOfCashoutTrans) AS COTransCnt
				FROM #Target t1
				WHERE t1.Currency = t.Currency
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s 
		WHERE s.CustID = t.CustID AND s.Currency = t.Currency AND s.recommend = t.recommend
			AND s.TicketPayout = t.TicketPayout AND s.CashoutComm = t.CashoutComm AND s.CashoutAmount = t.CashoutAmount 
			AND s.BuyBackAmt = t.BuyBackAmt AND s.BABuyBackAmt = t.BABuyBackAmt AND s.NumOfCashoutTrans = t.NumOfCashoutTrans
			AND s.NumOfCashoutTicket = t.NumOfCashoutTicket)
	GROUP BY Currency;
	
	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 0
	BEGIN
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM #Log WHERE CurrencyId <> 20)
	BEGIN
		SET @HasDataMismatch = 1;
	END
	ELSE
	BEGIN
		SET @HasDataMismatch = 2;
	END

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptLicCashoutSummary_CheckData', 
			TableName, 
			IsSource,
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log;

	DROP TABLE #Bettype;
	DROP TABLE #CashoutCust;
	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END