/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_rptLicCashoutSummary_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT = 0 OUTPUT -- 0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170523@Paul
	Task: Check & correct data of rptLicCashoutSummary - Check Member level only
	DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport
	
	Revisions:
		- 20181003@Bruce: LA - Should not include refund ticket for Cash Out Tickets [Redmine: #102578]
		- 20190510@Percy: Enhance Performance [RedmineID: #112596]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @n INT = 2147483647; -- max of int

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
		NumOfCashoutTrans	INT,
		NumOfCashoutTicket	INT
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
		NumOfCashoutTrans	INT,
		NumOfCashoutTicket	INT
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

	-- #Source
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
		WHERE b.winlostdate = @WinlostDate
			AND NOT EXISTS (SELECT 1 FROM #Bettype bt WHERE b.bettype = bt.Bettype AND bt.Bettype <> 913)
		GROUP BY b.refno

		DROP TABLE #Bettype
		DROP TABLE #CashoutCust

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
			NumOfCashoutTrans,
			NumOfCashoutTicket
		)
		SELECT
			b.custid
			,b.currency
			,b.recommend
			,SUM(ISNULL(pc.winlost, 0)) AS TicketPayout
			,SUM(ISNULL(pc.comm, 0)) AS CashoutComm
			,SUM(b.actual_stake) AS CashoutAmount
			,SUM(CASE WHEN b.customercategory = 1003 THEN b.winlost ELSE 0 END) AS BuyBackAmt
			,SUM(CASE WHEN b.customercategory = 1004 THEN b.winlost ELSE 0 END) AS BABuyBackAmt
			,SUM(1) AS NumOfCashoutTrans
			,0 AS NumOfCashoutTicket
		FROM dbo.bettrans b WITH (NOLOCK)
			LEFT JOIN #__PayoutComm pc ON b.transid = pc.refno
		WHERE b.winlostdate = @winlostdate AND b.bettype = 911
			AND b.statusID IN (111, 112, 113)
		GROUP BY
			b.custid
			,b.currency
			,b.recommend

		SET @S_Count = @@ROWCOUNT;

		DROP TABLE #__PayoutComm

		-- NumOfCashoutTicket
		SELECT DISTINCT b.refno
		INTO #__refno
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.WinlostDate = @winlostdate
			AND b.bettype = 911
			AND b.statusID IN (111, 112, 113)

		SELECT custid, currency, SUM(NumOfCashoutTicket) AS NumOfCashoutTicket
		INTO #__NoCOTicket
		FROM #__refno r
			CROSS APPLY (
				SELECT TOP (@n) b.custid, b.currency, COUNT(1) AS NumOfCashoutTicket
				FROM dbo.bettrans b WITH (NOLOCK)
				WHERE r.refno = b.transid
					AND b.statusID IN (111, 112, 113, 114, 115)
				GROUP BY b.custid, b.currency
			) AS b
		GROUP BY custid, currency
		OPTION (OPTIMIZE FOR (@n = 1))

		DROP TABLE #__refno

		UPDATE s
		SET s.NumOfCashoutTicket = n.NumOfCashoutTicket
		FROM #Source s
			INNER JOIN #__NoCOTicket n ON s.Currency = n.currency AND s.CustID = n.custid

		DROP TABLE #__NoCOTicket
	END
	-- End #Source

	-- #Target
	BEGIN
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
			NumOfCashoutTrans,
			NumOfCashoutTicket
		)
		SELECT
			CustID,
			Currency,
			Recommend,
			ISNULL(SUM(TicketPayout), 0),
			ISNULL(SUM(CashoutComm), 0),
			ISNULL(SUM(CashoutAmount), 0),
			ISNULL(SUM(BuyBackAmt), 0),
			ISNULL(SUM(BABuyBackAmt), 0),
			ISNULL(SUM(NumOfCashoutTrans), 0),
			ISNULL(SUM(NumOfCashoutTicket), 0)
		FROM dbo.rptLicCashoutSummary WITH (NOLOCK)
		WHERE Winlostdate = @WinlostDate
			AND RoleID = 1
		GROUP BY CustID, Currency, Recommend;

		SET @T_Count = @@ROWCOUNT;
	END
	-- End #Target

	-- Compare data
	BEGIN
		IF @S_Count = 0 AND @T_Count = 0
		BEGIN
			RETURN;
		END

		CREATE TABLE #Log (TableName VARCHAR(100), IsSource BIT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

		INSERT INTO #Log (TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
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
	
		IF @@ROWCOUNT = 0
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

		INSERT INTO dbo.DataCheckingLog (WinlostDate, SPName, TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
		SELECT @WinlostDate, 'Task_rptLicCashoutSummary_CheckData',TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo
		FROM #Log;

		DROP TABLE #Log;
		DROP TABLE #Source;
		DROP TABLE #Target;
	END

	SET NOCOUNT OFF;
END
GO