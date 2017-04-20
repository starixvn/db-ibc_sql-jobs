USE bodb_LicenseeReport
GO

ALTER PROCEDURE [dbo].[GEN_rptLicCashoutSummary]
	@FromDate DATETIME,
	@ToDate	DATETIME = NULL,
	@ProductCodes VARCHAR(1000) = 'CO'
AS
/*
	Created: 20170419@Harper
	Description: Daily summary data of Cashout [#71727]
	DB: DBEXT/bodb_LicenseeReport

	EXEC GEN_rptLicCashoutSummary '20170417'
*/
BEGIN
	IF @ToDate IS NULL
		SET @ToDate = @FromDate
	
	SET @ToDate =DATEADD(DAY, 1, @ToDate)
	
	DELETE FROM dbo.rptLicCashoutSummary
	WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate

	CREATE TABLE #Bettype (Bettype INT, ProductID INT)
	INSERT INTO #Bettype(Bettype, ProductID)
	SELECT Bettype,ProductID 
	FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)

	CREATE TABLE #CashoutCust (CustId INT PRIMARY KEY)
	INSERT INTO #CashoutCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetCashoutCustList('ALL')

	-- Member Level
	INSERT INTO dbo.rptLicCashoutSummary(
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			ProductID,
			RoleID,	
			Recommend,		
			Mrecommend,
			Srecommend,
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT b.winlostdate, b.custid, b.currency
		, ISNULL(site.SiteID,-1) siteid
		, ISNULL(bt.ProductID, 25)
		, 1
		, customer.recommend, customer.mrecommend, customer.srecommend
		, SUM(ISNULL(po.winlost, 0))
		, SUM(CASE WHEN b.bettype = 913 THEN b.awinlost ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1003 THEN b.winlost ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1004 THEN b.winlost ELSE 0 END)
		, SUM(CASE WHEN ISNULL(b.ExtraInfo, '') <> '' AND b.bettype <> 911 THEN 1 ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 THEN 1 ELSE 0 END)
	FROM dbo.bettrans b WITH (NOLOCK)	
		INNER JOIN bodb02.dbo.Dep_CustSuper s WITH(NOLOCK) ON b.srecommend = s.CustId
		INNER JOIN bodb02.dbo.customer WITH (NOLOCK) ON b.custid = customer.custid
		LEFT JOIN (
					SELECT b.refno, b.winlost
					FROM dbo.bettrans b
						INNER JOIN #CashoutCust ctc ON b.CustId = ctc.CustId
					WHERE b.bettype NOT IN (912, 913, 914)
				) po ON po.refno = b.transid
		LEFT JOIN #Bettype bt ON b.bettype = bt.Bettype
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON customer.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	WHERE statusid IN (111, 112, 113)
		AND (EXISTS (SELECT 1 FROM #Bettype bt2 WHERE b.bettype = bt2.Bettype) OR b.ExtraInfo IS NOT NULL)
	GROUP BY Winlostdate,	
		b.CustID,		
		b.Currency,
		ISNULL(site.SiteID,-1),
		ISNULL(bt.ProductID, 25),		
		customer.recommend, customer.mrecommend, customer.srecommend	

	-- Agent Level (Sum on member)
	INSERT INTO dbo.rptLicCashoutSummary(
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			ProductID,
			RoleID,	
			Recommend,		
			Mrecommend,
			Srecommend,
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT b.winlostdate, c.custid, b.currency
		, b.SiteID
		, b.ProductID
		, 2 AS RoleID
		, b.recommend, b.mrecommend, b.srecommend
		, SUM(TicketPayout)
		, SUM(CashoutComm)
		, SUM(CashoutAmount)
		, SUM(BuyBackAmt)
		, SUM(BABuyBackAmt)
		, SUM(NumOfCashoutTicket)
		, SUM(NumOfCashoutTrans)
	FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.recommend = c.custid  
	WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
		AND b.RoleID = 1 AND c.roleid = 2
	GROUP BY b.winlostdate, c.custid, b.currency
		,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend

	-- Master Level (Sum on member)
	INSERT INTO dbo.rptLicCashoutSummary(
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			ProductID,
			RoleID,	
			Recommend,		
			Mrecommend,
			Srecommend,
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT b.winlostdate, c.custid, b.currency
		, b.SiteID
		, b.ProductID
		, 3 AS RoleID
		, b.recommend, b.mrecommend, b.srecommend
		, SUM(TicketPayout)
		, SUM(CashoutComm)
		, SUM(CashoutAmount)
		, SUM(BuyBackAmt)
		, SUM(BABuyBackAmt)
		, SUM(NumOfCashoutTicket)
		, SUM(NumOfCashoutTrans)
	FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.Mrecommend = c.custid  
	WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
		AND b.RoleID = 1 AND c.roleid = 3
	GROUP BY b.winlostdate, c.custid, b.currency
		,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend
	
	-- Super Level (Sum on member)
	INSERT INTO dbo.rptLicCashoutSummary(
			Winlostdate,	
			CustID,		
			Currency,
			SiteID,
			ProductID,
			RoleID,	
			Recommend,		
			Mrecommend,
			Srecommend,
			TicketPayout,
			CashoutComm,
			CashoutAmount,
			BuyBackAmt,	
			BABuyBackAmt,
			NumOfCashoutTicket,
			NumOfCashoutTrans
	)
	SELECT b.winlostdate, c.custid, b.currency
		, b.SiteID
		, b.ProductID
		, 4 AS RoleID
		, b.recommend, b.mrecommend, b.srecommend
		, SUM(TicketPayout)
		, SUM(CashoutComm)
		, SUM(CashoutAmount)
		, SUM(BuyBackAmt)
		, SUM(BABuyBackAmt)
		, SUM(NumOfCashoutTicket)
		, SUM(NumOfCashoutTrans)
	FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.Srecommend = c.custid  
	WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
		AND b.RoleID = 1 AND c.roleid = 4
	GROUP BY b.winlostdate, c.custid, b.currency
		,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend
	
	-- END

	DROP TABLE #Bettype
	DROP TABLE #CashoutCust	

END
GO

GRANT VIEW DEFINITION ON [dbo].[GEN_rptLicCashoutSummary] TO [vnteam] AS [dbo]
GO
