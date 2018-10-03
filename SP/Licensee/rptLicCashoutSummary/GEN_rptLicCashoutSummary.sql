/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO


ALTER PROCEDURE [dbo].[GEN_rptLicCashoutSummary]
	@FromDate DATETIME,
	@ToDate	DATETIME = NULL,
	@ProductCodes VARCHAR(1000) = 'CO'
AS
/*
	Created: 20170419@Harper
	Description: Daily summary data of Cashout [RedmineID: #71727]
	DB: DBLIC.bodb_LicenseeReport

	Revision:
		-20170619@Harper: LA - Edit formula when cout CO ticket [Redmine: #78085]
		-20181003@Bruce: LA - Should not include refund ticket for Cash Out Tickets [Redmine: #102578]

	EXEC GEN_rptLicCashoutSummary '20170618'
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
	SELECT CustId FROM bodb02.dbo.f_GetCashoutCustList('ALL', 14) -- VendorID of Cashout
	
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
			NumOfCashoutTrans,
			NumOfCashoutTicket
	)
	SELECT b.winlostdate, b.custid, b.currency
		, ISNULL(site.SiteID,-1) siteid
		, 25
		, 1
		, customer.recommend, customer.mrecommend, customer.srecommend
		, SUM(ISNULL(po.winlost, 0))
		, SUM(ISNULL(comm.Comm, 0))
		, SUM(CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1003 THEN b.winlost ELSE 0 END)
		, SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1004 THEN b.winlost ELSE 0 END)		
		, SUM(CASE WHEN b.bettype = 911 THEN 1 ELSE 0 END)
		, 0
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
		customer.recommend, customer.mrecommend, customer.srecommend	
	
	;WITH cte AS (
			SELECT b.winlostdate, b.custid, b.currency, COUNT (*) AS numOfTicket
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE betdaqid = 0 AND b.bettype <> 911 AND CAST(ExtraInfo AS XML).exist('/p25/@s') = 1 and b.statusid IN (111, 112, 113)
			GROUP BY b.winlostdate, b.custid, b.currency
	)
	UPDATE b
	SET b.NumOfCashoutTicket = cte.numOfTicket
	FROM dbo.rptLicCashoutSummary b
		INNER JOIN cte ON b.Winlostdate = cte.winlostdate AND b.Currency = cte.currency AND b.CustID = cte.custid
						                              
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