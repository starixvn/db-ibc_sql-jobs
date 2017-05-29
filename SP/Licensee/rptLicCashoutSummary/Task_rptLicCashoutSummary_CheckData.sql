USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptLicCashoutSummary_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	BIT OUTPUT
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
			NumOfCashoutTrans
	)
	SELECT	b.custid, b.currency,
			b.recommend,
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
	WHERE statusid IN (111, 112, 113)	
		AND NOT EXISTS (SELECT 1 FROM #CashoutCust co WHERE co.CustId = b.CustID)
		AND b.winlostdate = @WinlostDate
	GROUP BY b.CustID,		
		b.Currency,
		b.recommend;

	SET @S_Count = @@ROWCOUNT;

	WITH cte AS (
			SELECT b.custid, b.currency, COUNT (*) AS numOfTicket
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE ISNULL(b.ExtraInfo, '') <> '' 
				AND b.bettype <> 911
				AND b.winlostdate = @WinlostDate
			GROUP BY b.custid, b.currency
	)
	UPDATE b
	SET b.NumOfCashoutTicket = cte.numOfTicket
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
	SELECT	TOP(@S_Count + 1) CustID,		
			Currency,
			Recommend,
			SUM(TicketPayout),
			SUM(CashoutComm),
			SUM(CashoutAmount),
			SUM(BuyBackAmt),	
			SUM(BABuyBackAmt),		
			SUM(NumOfCashoutTicket),
			SUM(NumOfCashoutTrans)
	FROM dbo.rptLicCashoutSummary WITH(NOLOCK)
	WHERE Winlostdate = @WinlostDate
		AND RoleID = 1
	GROUP BY CustID, Currency, Recommend;

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

	SELECT TOP(1) @i = 1
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t 
		WHERE s.CustID = t.CustID AND s.Currency = t.Currency AND s.recommend = t.recommend
			AND s.TicketPayout = t.TicketPayout AND s.CashoutComm = t.CashoutComm AND s.CashoutAmount = t.CashoutAmount 
			AND s.BuyBackAmt = t.BuyBackAmt AND s.BABuyBackAmt = t.BABuyBackAmt AND s.NumOfCashoutTrans = t.NumOfCashoutTrans
			AND s.NumOfCashoutTicket = t.NumOfCashoutTicket);
	
	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 1
	BEGIN
		SET @HasDataMismatch = 1;
	END

	SET NOCOUNT OFF;
END