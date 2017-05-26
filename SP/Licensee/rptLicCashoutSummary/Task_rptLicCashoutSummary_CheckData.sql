USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptLicCashoutSummary_CheckData]
	@WinlostDate SMALLDATETIME,
	@HasDataMismatch BIT = 0 OUTPUT
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rptLicCashoutSummary
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
*/

BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #Source 
	(
		Winlostdate			SMALLDATETIME,
		CustID				INT,
		Currency			INT,
		SiteID				INT,
		Recommend			INT,
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
		Winlostdate			SMALLDATETIME,
		CustID				INT,
		Currency			INT,
		SiteID				INT,
		Recommend			INT,
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
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			Recommend,	
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,			
			NumOfCashoutTrans
	)
	SELECT	b.winlostdate, b.custid, b.currency,
			ISNULL(site.SiteID,-1) siteid,
			customer.recommend,
			SUM(ISNULL(po.winlost, 0)),
			SUM(ISNULL(comm.Comm, 0)),
			SUM(CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE 0 END),
			SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1003 THEN b.winlost ELSE 0 END),
			SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1004 THEN b.winlost ELSE 0 END),
			SUM(CASE WHEN b.bettype = 911 THEN 1 ELSE 0 END)
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
		LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid AND ag.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON ag.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	WHERE statusid IN (111, 112, 113)	
		AND NOT EXISTS (SELECT 1 FROM #CashoutCust co WHERE co.CustId = b.CustID)
	GROUP BY Winlostdate,	
		b.CustID,		
		b.Currency,
		ISNULL(site.SiteID,-1),			
		customer.recommend;

	SET @S_Count = @@ROWCOUNT;

	WITH cte AS (
			SELECT b.winlostdate, b.custid, b.currency, COUNT (*) AS numOfTicket
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE ISNULL(b.ExtraInfo, '') <> '' AND b.bettype <> 911
			GROUP BY b.winlostdate, b.custid, b.currency
	)
	UPDATE b
	SET b.NumOfCashoutTicket = cte.numOfTicket
	FROM #Source b
		INNER JOIN cte ON b.Winlostdate = cte.winlostdate AND b.Currency = cte.currency AND b.CustID = cte.custid;

	INSERT INTO #Target
	(
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			Recommend,	
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,	
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT	TOP(@S_Count + 1) Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			Recommend,	
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,		
			NumOfCashoutTicket,
			NumOfCashoutTrans
	FROM dbo.rptLicCashoutSummary WITH(NOLOCK)
	WHERE Winlostdate = @WinlostDate
		AND RoleID = 1;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1;

		RETURN;
	END

	SELECT TOP(@S_Count + 1) @i = 1
	FROM #Source s
		FULL OUTER JOIN #Target t 
			ON s.CustID = t.CustID AND s.Currency = t.Currency AND s.SiteID = t.SiteID AND s.Recommend = t.Recommend
				AND s.TicketPayout = t.TicketPayout AND s.CashoutComm = t.CashoutComm AND s.CashoutAmount = t.CashoutAmount 
				AND s.BuyBackAmt = t.BuyBackAmt AND s.BABuyBackAmt = t.BABuyBackAmt AND s.NumOfCashoutTrans = t.NumOfCashoutTrans
				AND s.NumOfCashoutTicket = t.NumOfCashoutTicket
	
	SET @T_Count = @@ROWCOUNT;

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1;
	END

	SET NOCOUNT OFF;
END