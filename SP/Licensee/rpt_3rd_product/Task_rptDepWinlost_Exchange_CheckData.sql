/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptDepWinlost_Exchange_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20180406@Harper
	Task : Check & correct data of rptDepWinlost_ThirdParty - Exchange
	DB: DBLIC.bodb_LicenseeReport
	
	Revisions:
		- 20180406@Harper: Create new SP [RedmineID: #92485]
	
	DECLARE @HasDataMismatch	TINYINT
	EXEC Task_rptDepWinlost_Exchange_CheckData @WinlostDate = '2018-04-09', @HasDataMismatch = @HasDataMismatch OUTPUT
	SELECT @HasDataMismatch
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source
	(
		TableName		VARCHAR(100),
		Custid			INT,								
		Currency		INT,	
		ProductID		TINYINT,				
		Turnover		MONEY,							
		Winlost			MONEY,
		WinlostA		MONEY,
		DrawTO			MONEY,	
		DrawBetCount	INT,						
		BetCount		INT,
		CommissionP		MONEY,
		CommissionA		MONEY,
		ValidBetAmount	MONEY

	);

	CREATE TABLE #Target
	(
		Custid			INT,								
		Currency		INT,	
		ProductID		TINYINT,				
		Turnover		MONEY,							
		Winlost			MONEY,
		WinlostA		MONEY,
		DrawTO			MONEY,	
		DrawBetCount	INT,						
		BetCount		INT,
		CommissionP		MONEY,
		CommissionA		MONEY,
		ValidBetAmount	MONEY
	);

	CREATE TABLE #TicketData 
	(	Custid			INT,	
		SiteID			INT,							
		CurrencyID		INT,
		ExVirtualRate	FLOAT,
		UserID			VARCHAR(20),
		EventID			INT,
		MarketID		VARCHAR(50),							
		Turnover		MONEY,							
		Winlost			MONEY,	
		WinLostA		MONEY,
		DrawTO			MONEY,	
		DrawBetCount	INT,						
		BetCount		INT,
		ValidBetAmount	MONEY,
		CommissionP		MONEY,
		CommissionA		MONEY
	)
							
	CREATE TABLE #DetailData 
	(	
		UserID			VARCHAR(20),
		EventID			INT,
		MarketID		VARCHAR(50),
		DrawTO			MONEY,	
		DrawBetCount	INT,						
		BetCount		INT,
		Lay				MONEY,
		Back			MONEY
	)

	CREATE TABLE #ChargeRate 
	(
		PartyId			INT, 
		LicenseeId		INT, 
		ProductId		INT, 
		Rate			MONEY, 
		FromDate		DATE, 
		ToDate			DATE
	)

	DECLARE @S_Count INT, @T_Count INT,
			@i INT,
			@PartyList VARCHAR(4000)

	SELECT @PartyList = COALESCE(@PartyList + ',' + CAST(FromParty AS VARCHAR), CAST(FromParty AS VARCHAR))
	FROM (
		SELECT FromParty
		FROM bodb_licensee.dbo.OAS_ChargeInfo WITH(NOLOCK)
		WHERE ProductId = 31
		GROUP BY FromParty
	)tmp
	
	INSERT INTO #ChargeRate(PartyId, LicenseeId, ProductId, Rate, FromDate, ToDate)
	SELECT PartyId, LicenseeId, ProductId, DI_Rate, FromDate, ToDate
	FROM bodb_licensee.dbo.LA_f_ChargeInfo(@PartyList, @WinlostDate, @WinlostDate, 'BX', 'OA', 1)
	WHERE DI_Rate > 0 AND ChargeType = 1

	-- Get more charge rate for trial time
	INSERT INTO #ChargeRate(PartyId, LicenseeId, ProductId, Rate, FromDate, ToDate)
	SELECT PartyId, LicenseeId, ProductId, DI_Rate, FromDate, ToDate
	FROM bodb_licensee.dbo.LA_f_GetChargeInfoWithTrialTime(@PartyList, @WinlostDate, @WinlostDate, 'BX', 'OA', 1)
	WHERE DI_Rate > 0 AND ChargeType = 1

	INSERT INTO #TicketData (custid, SiteID, CurrencyID, ExVirtualRate, UserID, EventID, MarketID
									, Turnover, Winlost, CommissionP, CommissionA )
	SELECT b.CustID, ISNULL(site.SiteID,-1), b.Currency, b.ExVirtualRate, b.userId, b.eventID, b.marketID
		, SUM(b.stakeTotal * 1/b.ExVirtualRate), SUM(b.marketTotal * 1/b.ExVirtualRate)
		, SUM(b.commission * 1/b.ExVirtualRate), SUM(b.agentCommission * 1/b.ExVirtualRate)
	FROM bodb_3rdProduct.dbo.Sum_winloss_Exchange b WITH (NOLOCK)
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.Custid = b.CustID AND c.roleid = 1
		LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid AND ag.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON ag.site=ibcsite.site
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	WHERE CONVERT(DATE, b.settledDate) = @WinlostDate
	GROUP BY b.CustID, ISNULL(site.SiteID,-1), b.currency, b.ExVirtualRate, b.userId, b.eventID, b.marketID

	INSERT INTO #DetailData( UserID ,EventID ,MarketID ,BetCount  ,DrawBetCount ,DrawTO ,Lay ,Back )			
	SELECT d.userId, d.eventID, d.marketID
		, COUNT(*) AS Betcount
		, SUM(CASE WHEN d.profitLoss = 0 THEN 1 ELSE 0 END) AS DrawBetCount
		, SUM(CASE WHEN d.profitLoss = 0 THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS DrawTO
		, SUM(CASE WHEN d.matchType = 'Lay' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Lay
		, SUM(CASE WHEN d.matchType = 'Back' THEN (d.matchStake * 1/b.ExVirtualRate) ELSE 0 END) AS Back
	FROM bodb_3rdProduct.dbo.Bettrans_Exchange d WITH (NOLOCK)
		INNER JOIN #TicketData b ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID
	WHERE d.betstatus = 'Settled'				
	GROUP BY d.userId, d.eventID, d.marketID
			
	UPDATE b
	SET b.BetCount = ISNULL(d.BetCount, 0),
		b.DrawBetCount = ISNULL(d.DrawBetCount, 0),
		b.DrawTO = ISNULL(d.DrawTO, 0),
		b.ValidBetAmount = ABS(ISNULL(d.Lay, 0) - ISNULL(d.Back, 0))
	FROM #TicketData b
		INNER JOIN #DetailData d ON d.userId = b.userId AND d.eventID = b.eventID AND d.marketID = b.marketID
				
	UPDATE b
	SET b.WinLostA = - (ISNULL(Winlost, 0)) * (1 - ISNULL(r.Rate, 0))
	FROM #TicketData b
		INNER JOIN #ChargeRate r ON b.SiteID = r.LicenseeId
	WHERE @WinlostDate BETWEEN r.FromDate AND r.ToDate

	INSERT INTO #Source
	        ( TableName ,
	          Custid ,
	          Currency ,
	          ProductID ,
	          Turnover ,
	          Winlost ,
	          WinlostA ,
	          DrawTO ,
	          DrawBetCount ,
	          BetCount ,
	          CommissionP ,
	          CommissionA ,
	          ValidBetAmount
	        )	
	SELECT	'Sum_winloss_Exchange',
			b.CustID, 		
			b.CurrencyID,	
			31,			
			SUM(ISNULL(b.turnover, 0)) AS Turnover,			
			SUM(ISNULL(Winlost, 0)) AS Winlost,	
			SUM(ISNULL(WinlostA, 0)) AS WinlostA,	
			SUM(ISNULL(b.DrawTO, 0)) AS DrawTO,
			SUM(ISNULL(DrawBetCount, 0)) AS DrawBetCount,	
			SUM(ISNULL(b.BetCount,0)) AS Betcount,
			SUM(ISNULL(CommissionP, 0)), 
			SUM(ISNULL(CommissionA, 0)), 
			SUM(ISNULL(ValidBetAmount, 0))			
	FROM #TicketData b 
	GROUP BY b.CustID, b.CurrencyID;

	SET @S_Count = @@ROWCOUNT;
	
	INSERT INTO #Target
	        ( Custid ,
	          Currency ,
	          ProductID ,
	          Turnover ,
	          Winlost ,
	          WinlostA ,
	          DrawTO ,
	          DrawBetCount ,
	          BetCount ,
	          CommissionP ,
	          CommissionA ,
	          ValidBetAmount
	        )
	SELECT custid, Currency, 31
					, SUM(ISNULL(turnover, 0)), SUM(ISNULL(Winlost, 0)), SUM(ISNULL(WinLostA, 0))
					, SUM(ISNULL(DrawTO, 0)), SUM(ISNULL(DrawBetCount, 0)), SUM(ISNULL(BetCount, 0))
					, SUM(ISNULL(CommissionP, 0)), SUM(ISNULL(CommissionA, 0)), SUM(ISNULL(ValidBetAmount, 0))		
	FROM bodb_LicenseeReport.dbo.rptDepWinlost_ThirdParty t WITH (NOLOCK)
	WHERE t.Winlostdate = @WinlostDate AND t.ProductId = 31
	GROUP BY t.CustID, t.Currency

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, CustID INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, CustID, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT TableName, 1, Custid, Currency, SUM(turnover), SUM(winlost), SUM(betCount),
			(
				SELECT Custid AS Custid, SUM(drawTO) AS drawTO, SUM(drawBetCount) AS drawBetCnt, SUM(WinlostA) AS WinlostA	
					, SUM(CommissionP) AS CommissionP, SUM(CommissionA) AS CommissionA, SUM(ValidBetAmount) AS ValidBetAmount
				FROM #Source s1
				WHERE s1.TableName = s.TableName
					AND s1.Custid = s.Custid
					AND s1.currency = s.currency					
				GROUP BY s1.Custid
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.turnover = t.turnover AND s.winlost = t.winlost
			AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount AND t.WinlostA = s.WinlostA 
			AND t.CommissionP = s.CommissionP AND t.CommissionA = s.CommissionA AND t.ValidBetAmount = s.ValidBetAmount AND s.ProductID = t.ProductID)
	GROUP BY TableName, ProductID, currency, CustID
	
	UNION ALL
	
	SELECT 'rptDepWinlost_ThirdParty', 0, Custid, Currency, SUM(turnover), SUM(winlost), SUM(betCount),
			(
				SELECT Custid AS CustID, SUM(drawTO) AS drawTO, SUM(drawBetCount) AS drawBetCnt, SUM(WinlostA) AS WinlostA	
					, SUM(CommissionP) AS CommissionP, SUM(CommissionA) AS CommissionA, SUM(ValidBetAmount) AS ValidBetAmount
				FROM #Target t1
				WHERE t1.ProductID = t.ProductID
					AND t1.currency = t.currency
					AND t1.Custid = t.CustID
				GROUP BY Custid
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.turnover = t.turnover AND s.winlost = t.winlost
			AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount AND s.WinlostA = t.WinlostA 
			AND s.CommissionP = t.CommissionP AND s.CommissionA = t.CommissionA AND s.ValidBetAmount = t.ValidBetAmount AND s.ProductID = t.ProductID)
	GROUP BY ProductID, currency, Custid

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
			'Task_rptDepWinlost_Exchange_CheckData', 
			TableName, 
			IsSource,			
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log;

	DROP TABLE #Log
	DROP TABLE #Source
	DROP TABLE #Target
	DROP TABLE #DetailData
	DROP TABLE #TicketData
	DROP TABLE #ChargeRate

	SET NOCOUNT OFF;
END
GO