/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptLicCashoutSummary]
	@FromDate		DATETIME,
	@ToDate			DATETIME = NULL,
	@ProductCodes	VARCHAR(1000) = 'CO'
AS

/*
	Created: 20170419@Harper
	Description: Daily summary data of Cashout [RedmineID: #71727]
	DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport

	Revisions:
		- 20170619@Harper: LA - Edit formula when cout CO ticket [Redmine: #78085]
		- 20181003@Bruce: LA - Should not include refund ticket for Cash Out Tickets [Redmine: #102578]
		- 20190510@Percy: Enhance Performance [RedmineID: #112596]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]

	EXEC GEN_rptLicCashoutSummary @FromDate = '2019-05-10', @ToDate = '2019-05-12', @ProductCodes = 'CO'
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @n INT = 2147483647 -- max of int

	IF @ToDate IS NULL
		SET @ToDate = @FromDate
	
	SET @ToDate = DATEADD(DAY, 1, @ToDate)

	IF @FromDate > @ToDate
		RETURN
	
	CREATE TABLE #Bettype (Bettype INT, ProductID INT)
	INSERT INTO #Bettype(Bettype, ProductID)
	SELECT Bettype,ProductID 
	FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)

	CREATE TABLE #CashoutCust (CustId INT PRIMARY KEY)
	INSERT INTO #CashoutCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetCashoutCustList('ALL', 14) -- VendorID of Cashout

	DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME)
	;WITH CTE_WinlostDate AS (
		SELECT @FromDate AS WinlostDate
		UNION ALL
		SELECT DATEADD(DAY, 1, WinlostDate)
		FROM CTE_WinlostDate
		WHERE WinlostDate < DATEADD(DAY, -1, @ToDate)
	)
	INSERT INTO @tblWinlostDate (WinlostDate)
	SELECT WinlostDate FROM CTE_WinlostDate
	OPTION (MAXRECURSION 0)

	DECLARE @tblWinlostDateBettype TABLE (WinlostDate SMALLDATETIME, Bettype INT)
	INSERT INTO @tblWinlostDateBettype (WinlostDate, Bettype)
	SELECT wld.WinlostDate, b.Bettype
	FROM @tblWinlostDate wld
		CROSS JOIN #Bettype b
	WHERE b.bettype = 911

	-- Delete old data
	DELETE dbo.rptLicCashoutSummary WITH (ROWLOCK, UPDLOCK)
	WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate

	/* ===== Member Level ===== */
	BEGIN
		-- TicketPayout, CashoutComm
		CREATE TABLE #__PayoutComm (refno BIGINT, winlost MONEY, comm MONEY)

		INSERT INTO #__PayoutComm (refno, winlost, comm)
		SELECT
			b.refno
			,SUM(CASE WHEN b.bettype = 913 THEN 0 ELSE b.winlost END) AS winlost
			,SUM(CASE WHEN b.bettype = 913 THEN b.awinlost ELSE 0 END) AS comm
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #CashoutCust c ON b.custid = c.custid
		WHERE b.winlostdate >= @FromDate AND b.winlostdate < @ToDate
			AND NOT EXISTS (SELECT 1 FROM #Bettype bt WHERE b.bettype = bt.Bettype AND bt.Bettype <> 913)
		GROUP BY b.refno

		DROP TABLE #Bettype
		DROP TABLE #CashoutCust
	
		-- rptLicCashoutSummary
		INSERT INTO dbo.rptLicCashoutSummary
		(
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
		SELECT
			b.Winlostdate,
			b.CustID,
			b.Currency,
			b.SiteID,
			25 AS ProductID,
			1 AS RoleID,
			b.Recommend,
			b.Mrecommend,
			b.Srecommend,
			b.TicketPayout,
			b.CashoutComm,
			b.CashoutAmount,
			b.BuyBackAmt,
			b.BABuyBackAmt,
			b.NumOfCashoutTrans,
			0 AS NumOfCashoutTicket
		FROM @tblWinlostDateBettype t
			CROSS APPLY (
				SELECT TOP (@n)
					b.winlostdate
					,b.custid
					,b.currency
					,ISNULL(site.SiteID, -1) AS siteid
					,ag.recommend
					,ag.mrecommend
					,ag.srecommend
					,SUM(ISNULL(pc.winlost, 0)) AS TicketPayout
					,SUM(ISNULL(pc.comm, 0)) AS CashoutComm
					,SUM(CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE 0 END) AS CashoutAmount
					,SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1003 THEN b.winlost ELSE 0 END) AS BuyBackAmt
					,SUM(CASE WHEN b.bettype = 911 AND b.customercategory = 1004 THEN b.winlost ELSE 0 END) AS BABuyBackAmt
					,SUM(CASE WHEN b.bettype = 911 THEN 1 ELSE 0 END) AS NumOfCashoutTrans
				FROM dbo.bettrans b WITH (NOLOCK)
					LEFT JOIN #__PayoutComm pc ON b.transid = pc.refno
					INNER JOIN bodb02.dbo.Customer ag WITH (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
					LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON ag.site = ibcsite.site
					LEFT JOIN bodb_Licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid = site.IbcSiteID
				WHERE b.winlostdate = t.WinlostDate AND b.bettype = t.Bettype
					AND b.statusID IN (111, 112, 113)
				GROUP BY
					b.winlostdate
					,b.custid
					,b.currency
					,ISNULL(site.SiteID, -1)
					,ag.recommend
					,ag.mrecommend
					,ag.srecommend
			) AS b
		OPTION (OPTIMIZE FOR (@n = 1))

		DROP TABLE #__PayoutComm

		-- NumOfCashoutTicket
		SELECT DISTINCT refno
		INTO #__refno
		FROM @tblWinlostDate wld
			CROSS APPLY (
				SELECT TOP (@n) b.refno
				FROM dbo.bettrans b WITH (NOLOCK)
				WHERE wld.WinlostDate = b.winlostdate
					AND b.bettype = 911
					AND b.statusID IN (111, 112, 113)
			) AS b
		OPTION (OPTIMIZE FOR (@n = 1))

		SELECT winlostdate, custid, currency, SUM(NumOfCashoutTicket) AS NumOfCashoutTicket
		INTO #__NoCOTicket
		FROM #__refno r
			CROSS APPLY (
				SELECT TOP (@n) b.winlostdate, b.custid, b.currency, COUNT(1) AS NumOfCashoutTicket
				FROM dbo.bettrans b WITH (NOLOCK)
				WHERE r.refno = b.transid
					AND b.statusID IN (111, 112, 113, 114, 115)
				GROUP BY b.winlostdate, b.custid, b.currency
			) AS b
		GROUP BY winlostdate, custid, currency
		OPTION (OPTIMIZE FOR (@n = 1))

		DROP TABLE #__refno

		UPDATE r
		SET r.NumOfCashoutTicket = n.NumOfCashoutTicket
		FROM dbo.rptLicCashoutSummary r WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #__NoCOTicket n ON r.Winlostdate = n.winlostdate AND r.Currency = n.currency AND r.CustID = n.custid
	END
	/* ===== End Member Level ===== */
						                              
	/* ===== Agent Level - sum of member ===== */
	BEGIN
		INSERT INTO dbo.rptLicCashoutSummary
		(
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
			, SUM(NumOfCashoutTrans)
			, SUM(NumOfCashoutTicket)
		FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.recommend = c.custid
		WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
			AND b.RoleID = 1 AND c.roleid = 2
		GROUP BY b.winlostdate, c.custid, b.currency
			,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend
	END
	/* ===== End Agent Level ===== */

	/* ===== Master Level - sum of member ===== */
	BEGIN
		INSERT INTO dbo.rptLicCashoutSummary
		(
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
			, SUM(NumOfCashoutTrans)
			, SUM(NumOfCashoutTicket)
		FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.Mrecommend = c.custid
		WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
			AND b.RoleID = 1 AND c.roleid = 3
		GROUP BY b.winlostdate, c.custid, b.currency
			,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend
	END
	/* ===== End Master Level ===== */
	
	/* ===== Super Level - sum of member ===== */
	BEGIN
		INSERT INTO dbo.rptLicCashoutSummary
		(
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
			, SUM(NumOfCashoutTrans)
			, SUM(NumOfCashoutTicket)
		FROM dbo.rptLicCashoutSummary b WITH (NOLOCK)
			INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON b.Srecommend = c.custid
		WHERE Winlostdate >= @FromDate AND Winlostdate < @ToDate
			AND b.RoleID = 1 AND c.roleid = 4
		GROUP BY b.winlostdate, c.custid, b.currency
			,b.SiteID, b.ProductID, b.recommend, b.mrecommend, b.srecommend
	END
	/* ===== End Super Level ===== */
END
GO