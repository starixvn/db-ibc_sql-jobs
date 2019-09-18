/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_LicenseeReport
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[Task_rptBetting_CheckData]
    @WinlostDate		DATETIME
	,@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
	,@BetTypes			VARCHAR(MAX) OUTPUT
AS
/*
Created: 20170522@Sophia
Task: Check sum rpt_Betting vs Staging bettrans table (Exclude separate wallet 3rd Product : AGC and GD) [Redmine: #72914]
DB: DBLIC.bodb_LicenseeReport

Revisions:
		- 20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
		- 20190520@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20190808@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]
		- 20190918@Parsons: Update house turnover's formula [Redmine: #120119]
		
Param's Explanation:

DECLARE @HasDataMismatch BIT
EXEC Task_rptBetting_CheckData @WinlostDate = '2017-05-05',   @HasDataMismatch = @HasDataMismatch OUTPUT
SELECT @HasDataMismatch 

*/
BEGIN 
	SET NOCOUNT ON 	

	SET @HasDataMismatch = 0

	CREATE TABLE #Source 
	(
		SiteID		INT,
		Bettype		SMALLINT,
		CurrencyID	INT,
		Status		SMALLINT,		
		BetCount	INT,
		MemberCount	INT,
		Turnover	MONEY,
		WinLoss		MONEY,
		WinLossA	MONEY,
		WinLossM	MONEY,
		WinLossS	MONEY,
		CommissionP	MONEY,
		CommissionA	MONEY,
		CommissionM	MONEY,
		CommissionS	MONEY,
		CustomerCategory	SMALLINT,
		BuyBackAmount	MONEY,
		WinPrizeAmount	MONEY,
		CashOutAmount	MONEY,
		oddsspread		MONEY,
		TicketType		TINYINT,
		ExtraAmount		MONEY,
		tpositiontaking SMALLMONEY
	);

	CREATE TABLE #Target 
	(
		SiteID		INT,
		Bettype		SMALLINT,
		CurrencyID	INT,
		Status		SMALLINT,		
		BetCount	INT,
		MemberCount	INT,
		Turnover	MONEY,
		WinLoss		MONEY,
		WinLossA	MONEY,
		WinLossM	MONEY,
		WinLossS	MONEY,
		CommissionP	MONEY,
		CommissionA	MONEY,
		CommissionM	MONEY,
		CommissionS	MONEY,
		CustomerCategory	SMALLINT,
		BuyBackAmount	MONEY,
		WinPrizeAmount	MONEY,
		CashOutAmount	MONEY,
		oddsspread		MONEY,
		TicketType		TINYINT,
		ExtraAmount		MONEY,
		tpositiontaking SMALLMONEY
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT

	INSERT INTO #Source (SiteID,Bettype, CurrencyID, Status, BetCount, MemberCount,	
						Turnover, WinLoss, WinLossA, WinLossM, WinLossS, 
						CommissionP, CommissionA, CommissionM, CommissionS,	CustomerCategory, 
						BuyBackAmount, WinPrizeAmount, CashOutAmount, oddsspread, TicketType, ExtraAmount,tpositiontaking)
	SELECT	SiteID, Bettype, Currency, Status, ISNULL(SUM(BetCount), 0), ISNULL(SUM(MemberCount), 0),	
			ISNULL(SUM(Turnover), 0), ISNULL(SUM(WinLoss), 0), ISNULL(SUM(WinLossA), 0), ISNULL(SUM(WinLossM), 0),
			ISNULL(SUM(WinLossS), 0), ISNULL(SUM(CommissionP), 0), ISNULL(SUM(CommissionA), 0), ISNULL(SUM(CommissionM), 0),
			ISNULL(SUM(CommissionS), 0), CustomerCategory, ISNULL(SUM(BuyBackAmount), 0), ISNULL(SUM(WinPrizeAmount), 0),
			ISNULL(SUM(CashOutAmount), 0), ISNULL(SUM(oddsspread), 0), TicketType, ISNULL(SUM(ExtraAmount), 0),tpositiontaking
	FROM (
		SELECT  
			ISNULL(site.SiteID,-1) siteid,
			b.bettype, 
			CASE 
				WHEN b.bettype=9 THEN -9 
				WHEN b.bettype = 2799 THEN -2799
				WHEN b.bettype = 10 OR (b.bettype<>38 AND b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)
				WHEN b.bettype IN(1231,1232,1233,1237,1238) THEN RaceInfo.LeagueID
				ELSE ISNULL(m.leagueid,-1) 
			END AS leagueid,
			b.currency,
			b.statusid Status,
			COUNT(*) Betcount,
			COUNT(DISTINCT b.custid) MemberCount,		
			SUM(stake) Turnover,
			SUM(winlost-actual_stake) winloss,
			SUM(awinlost) winlossA,
			SUM(mwinlost) winlossM,
			SUM(swinlost) winlossS,
			SUM(playercomm) commissionP,
			SUM(comm) commissionA,
			SUM(acomm) commissionM,
			SUM(scomm) commissionS,
			b.customercategory,
			SUM(CASE 
					WHEN b.bettype IN (901, 911) THEN winlost 
					WHEN b.bettype = 18000 THEN ISNULL(CashInAmount,0)
					ELSE 0 
				END) BuyBackAmount,
			SUM(ISNULL(WinPrizeAmount,0)) WinPrizeAmount,
			SUM(ISNULL(CashOutAmount,0)) CashOutAmount, -- Cashout Value of Cashout Product		
			SUM(CASE WHEN b.bettype=1004 THEN 0 ELSE ISNULL(oddsspread,0) END)    oddsspread,
			b.TicketType,
			SUM(CASE
				WHEN b.bettype BETWEEN 1401 AND 1499 THEN CONVERT(MONEY, ISNULL(b.ExtraInfo, 0)) -- poker games: gem & insurance
				WHEN b.bettype = 18000 THEN CONVERT(MONEY, ISNULL(b.ExtraInfo, 0)) -- Extra Amount For CB Free Play Ticket
				WHEN b.bettype BETWEEN 81 AND 120 OR b.bettype BETWEEN 8101 AND 8120 THEN b.stake * (1 - b.tpositiontaking) -- House Turnover In NG WL
				ELSE 0 END) ExtraAmount,
			CASE WHEN b.bettype=1004 THEN b.tpositiontaking ELSE 0 END tpositiontaking-- bullfighting
		FROM
			dbo.bettrans b (NOLOCK) 
			LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
			LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
			LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
			LEFT JOIN DBRPT.bodb02.dbo.VSRaceInfo RaceInfo WITH (NOLOCK) ON b.matchid = RaceInfo.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
		WHERE isBA=0 AND b.winlostdate=@WinlostDate
		GROUP BY
			ISNULL(site.SiteID,-1),
			b.bettype, 
			CASE 
				WHEN b.bettype=9 THEN -9 
				WHEN b.bettype = 2799 THEN -2799
				WHEN b.bettype = 10 OR (b.bettype<>38 AND b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)
				WHEN b.bettype IN(1231,1232,1233,1237,1238) THEN RaceInfo.LeagueID
				ELSE ISNULL(m.leagueid,-1) 
			END,	
			b.currency,
			b.statusid,
			b.liveindicator,
			b.customercategory,
			b.TicketType,
			CASE WHEN b.bettype=1004 THEN b.tpositiontaking ELSE 0 END
	) d
	GROUP BY SiteID, Bettype, Currency, Status, CustomerCategory, TicketType,tpositiontaking

	SET @S_Count = @@ROWCOUNT

	INSERT INTO #Target (SiteID, Bettype, CurrencyID, Status, BetCount, MemberCount,	
						Turnover, WinLoss, WinLossA, WinLossM, WinLossS, 
						CommissionP, CommissionA, CommissionM, CommissionS,	CustomerCategory, 
						BuyBackAmount, WinPrizeAmount, CashOutAmount, oddsspread, TicketType, ExtraAmount,tpositiontaking)
	SELECT	SiteID, Bettype, CurrencyID, Status, ISNULL(SUM(BetCount), 0), ISNULL(SUM(MemberCount), 0),
			ISNULL(SUM(Turnover), 0), ISNULL(SUM(WinLoss), 0), ISNULL(SUM(WinLossA), 0), ISNULL(SUM(WinLossM), 0),
			ISNULL(SUM(WinLossS), 0), ISNULL(SUM(CommissionP), 0), ISNULL(SUM(CommissionA), 0), ISNULL(SUM(CommissionM), 0),
			ISNULL(SUM(CommissionS), 0), CustomerCategory, ISNULL(SUM(BuyBackAmount), 0), ISNULL(SUM(WinPrizeAmount), 0),
			ISNULL(SUM(CashOutAmount), 0), SUM(CASE WHEN bettype=1004 THEN 0 ELSE ISNULL(oddsspread,0) END), TicketType, ISNULL(SUM(ExtraAmount), 0),
			CASE WHEN bettype=1004 THEN oddsspread ELSE 0 END
	FROM dbo.rpt_betting WITH (NOLOCK)
	WHERE RptDate = @WinlostDate 
	GROUP BY SiteID, Bettype, CurrencyID, Status, CustomerCategory,TicketType,CASE WHEN bettype=1004 THEN oddsspread ELSE 0 END
		   
	SET @T_Count = @@ROWCOUNT

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN
	END
	
	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, BetTypeId INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX))

	INSERT INTO #Log(TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT 'staging bettrans', 1, Bettype, CurrencyID, SUM(Turnover), SUM(WinLoss), SUM(BetCount),
			(
				SELECT	SUM(MemberCount) AS MemCnt, SUM(WinLossA) AS WLA, SUM(WinLossM) AS WLM, SUM(WinLossS) AS WLS, 
						SUM(CommissionP) AS CommP, SUM(CommissionA) AS CommA, SUM(CommissionM) AS CommM, SUM(CommissionS) AS CommS,
						SUM(BuyBackAmount) AS BuyBackAmt, SUM(WinPrizeAmount) AS WinPrizeAmt, SUM(CashOutAmount) AS COAmt, SUM(oddsspread) AS oddsspread,
						SUM(ExtraAmount) AS ExtraAmount, s.TicketType, s.tpositiontaking
				FROM #Source s1
				WHERE s1.Bettype = s.Bettype
					AND s1.CurrencyID = s.CurrencyID AND s1.TicketType = s.TicketType AND s1.tpositiontaking = s.tpositiontaking
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t 
		WHERE s.SiteId = t.SiteId AND s.Bettype = t.Bettype AND s.CurrencyID = t.CurrencyID 
				AND s.Status = t.Status AND s.CustomerCategory = t.CustomerCategory AND s.BetCount = t.BetCount
				AND s.MemberCount = t.MemberCount AND s.Turnover = t.Turnover AND s.WinLoss = t.WinLoss
				AND s.WinLossA = t.WinLossA AND s.WinLossM = t.WinLossM AND s.WinLossS = t.WinLossS 
				AND s.CommissionP = t.CommissionP AND s.CommissionA = t.CommissionA AND s.CommissionM = t.CommissionM
				AND s.CommissionS = t.CommissionS AND s.BuyBackAmount = t.BuyBackAmount AND s.WinPrizeAmount = t.WinPrizeAmount
				AND s.TicketType = t.TicketType AND s.ExtraAmount = t.ExtraAmount AND s.tpositiontaking = t.tpositiontaking
				AND s.CashOutAmount = t.CashOutAmount AND s.oddsspread = t.oddsspread)
	GROUP BY Bettype, CurrencyID, TicketType, tpositiontaking

	UNION ALL

	SELECT 'rpt_betting', 0, Bettype, CurrencyID, SUM(Turnover), SUM(WinLoss), SUM(BetCount),
			(
				SELECT	SUM(MemberCount) AS MemCnt, SUM(WinLossA) AS WLA, SUM(WinLossM) AS WLM, SUM(WinLossS) AS WLS, 
						SUM(CommissionP) AS CommP, SUM(CommissionA) AS CommA, SUM(CommissionM) AS CommM, SUM(CommissionS) AS CommS,
						SUM(BuyBackAmount) AS BuyBackAmt, SUM(WinPrizeAmount) AS WinPrizeAmt, SUM(CashOutAmount) AS COAmt, SUM(oddsspread) AS oddsspread,
						SUM(ExtraAmount) AS ExtraAmount,t.TicketType,t.tpositiontaking
				FROM #Target t1
				WHERE t1.Bettype = t.Bettype
					AND t1.CurrencyID = t.CurrencyID AND t1.TicketType = t.TicketType AND t1.tpositiontaking = t.tpositiontaking
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s 
		WHERE s.SiteId = t.SiteId AND s.Bettype = t.Bettype AND s.CurrencyID = t.CurrencyID 
				AND s.Status = t.Status AND s.CustomerCategory = t.CustomerCategory AND s.BetCount = t.BetCount
				AND s.MemberCount = t.MemberCount AND s.Turnover = t.Turnover AND s.WinLoss = t.WinLoss
				AND s.WinLossA = t.WinLossA AND s.WinLossM = t.WinLossM AND s.WinLossS = t.WinLossS 
				AND s.CommissionP = t.CommissionP AND s.CommissionA = t.CommissionA AND s.CommissionM = t.CommissionM
				AND s.CommissionS = t.CommissionS AND s.BuyBackAmount = t.BuyBackAmount AND s.WinPrizeAmount = t.WinPrizeAmount
				AND s.TicketType = t.TicketType AND s.ExtraAmount = t.ExtraAmount AND s.tpositiontaking = t.tpositiontaking
				AND s.CashOutAmount = t.CashOutAmount AND s.oddsspread = t.oddsspread)
	GROUP BY Bettype, CurrencyID,TicketType,tpositiontaking

	SET @T_Count = @@ROWCOUNT

	IF @T_Count = 0
	BEGIN
		RETURN
	END

	IF EXISTS (SELECT 1 FROM #Log WHERE CurrencyId <> 20)
	BEGIN
		SET @HasDataMismatch = 1
	END
	ELSE
	BEGIN
		SET @HasDataMismatch = 2
	END

	SELECT @BetTypes = STUFF(
			(
				SELECT DISTINCT ', ' + CAST(BetTypeId AS VARCHAR(10))
				FROM #Log
				FOR XML PATH('')
			), 1, 2, ''
		)

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptBetting_CheckData', 
			TableName, 
			IsSource,
			BetTypeId, 
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log

	DROP TABLE #Log
	DROP TABLE #Source
	DROP TABLE #Target

	SET NOCOUNT OFF
END 
GO