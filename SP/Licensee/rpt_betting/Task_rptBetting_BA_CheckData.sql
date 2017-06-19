/*<info serverAlias="DBLIC-bodb_LicenseeReport," executers="" viewers="vnteam" isFunction="0" isNested=”0”></info>*/
USE bodb_LicenseeReport
GO
ALTER PROCEDURE [dbo].[Task_rptBetting_BA_CheckData]
    @WinlostDate		datetime
	,@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
Created: 20170522@Sophia
Task: Check sum rpt_Betting_BA vs Staging bettrans table (Exclude separate wallet 3rd Product : AGC and GD) [Redmine: #72914]
DB: DBLIC.bodb_LicenseeReport

Revisions:
	
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
		BuyBackAmount	MONEY 
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
		BuyBackAmount	MONEY 
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT

	INSERT INTO #Source (SiteID,Bettype, CurrencyID, Status, BetCount, MemberCount,	
						Turnover, WinLoss, WinLossA, WinLossM, WinLossS, 
						CommissionP, CommissionA, CommissionM, CommissionS,	CustomerCategory, 
						BuyBackAmount)
	SELECT	SiteID, Bettype, Currency, Status, ISNULL(SUM(BetCount), 0), ISNULL(SUM(MemberCount), 0),	
			ISNULL(SUM(Turnover), 0), ISNULL(SUM(WinLoss), 0), ISNULL(SUM(WinLossA), 0), ISNULL(SUM(WinLossM), 0),
			ISNULL(SUM(WinLossS), 0), ISNULL(SUM(CommissionP), 0), ISNULL(SUM(CommissionA), 0), ISNULL(SUM(CommissionM), 0),
			ISNULL(SUM(CommissionS), 0), CustomerCategory, ISNULL(SUM(BuyBackAmount), 0)
	FROM (
		SELECT  
			ISNULL(site.SiteID,-1) siteid,
			b.bettype,
			CASE 
				WHEN b.bettype=9 THEN -9 
				WHEN (b.bettype=10) OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
				ELSE ISNULL(m.leagueid,-1) 
			END AS leagueid,	
			b.currency,
			ISNULL(sta.statusid,-1) [Status],
			ISNULL(b.liveindicator,0) liveindicator,
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
			SUM(CASE WHEN b.bettype IN (901) THEN winlost ELSE 0 END) AS BuyBackAmount	
		FROM
			dbo.bettrans b (NOLOCK) 
			LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
			LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID	
			LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
			LEFT JOIN bodb_Licensee.dbo.view_status_list sta (NOLOCK) ON b.Status = sta.StatusName
		WHERE isBA=1
		GROUP BY
			ISNULL(site.SiteID,-1),
			b.bettype,
			CASE 
				WHEN b.bettype=9 THEN -9 
				WHEN (b.bettype=10) OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
				ELSE ISNULL(m.leagueid,-1) 
			END,	
			b.currency,
			ISNULL(sta.statusid,-1),
			b.liveindicator,
			b.customercategory
	) d
	GROUP BY SiteID, Bettype, Currency, Status, CustomerCategory

	SET @S_Count = @@ROWCOUNT

	INSERT INTO #Target (SiteID, Bettype, CurrencyID, Status, BetCount, MemberCount,	
						Turnover, WinLoss, WinLossA, WinLossM, WinLossS, 
						CommissionP, CommissionA, CommissionM, CommissionS,	CustomerCategory, 
						BuyBackAmount)
	SELECT	SiteID, Bettype, CurrencyID, Status, ISNULL(SUM(BetCount), 0), ISNULL(SUM(MemberCount), 0),	
			ISNULL(SUM(Turnover), 0), ISNULL(SUM(WinLoss), 0), ISNULL(SUM(WinLossA), 0), ISNULL(SUM(WinLossM), 0),
			ISNULL(SUM(WinLossS), 0), ISNULL(SUM(CommissionP), 0), ISNULL(SUM(CommissionA), 0), ISNULL(SUM(CommissionM), 0),
			ISNULL(SUM(CommissionS), 0), CustomerCategory, ISNULL(SUM(BuyBackAmount), 0)
	FROM dbo.rpt_betting_BA WITH (NOLOCK)
	WHERE RptDate = @WinlostDate 
	GROUP BY SiteID, Bettype, CurrencyID, Status, CustomerCategory
		   
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
						SUM(BuyBackAmount) AS BuyBackAmt
				FROM #Source s1
				WHERE s1.Bettype = s.Bettype
					AND s1.CurrencyID = s.CurrencyID
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
				AND s.CommissionS = t.CommissionS AND s.BuyBackAmount = t.BuyBackAmount) 
	GROUP BY Bettype, CurrencyID

	UNION ALL

	SELECT 'rpt_betting_BA', 0, Bettype, CurrencyID, SUM(Turnover), SUM(WinLoss), SUM(BetCount),
			(
				SELECT	SUM(MemberCount) AS MemCnt, SUM(WinLossA) AS WLA, SUM(WinLossM) AS WLM, SUM(WinLossS) AS WLS, 
						SUM(CommissionP) AS CommP, SUM(CommissionA) AS CommA, SUM(CommissionM) AS CommM, SUM(CommissionS) AS CommS,
						SUM(BuyBackAmount) AS BuyBackAmt
				FROM #Target t1
				WHERE t1.Bettype = t.Bettype
					AND t1.CurrencyID = t.CurrencyID
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
				AND s.CommissionS = t.CommissionS AND s.BuyBackAmount = t.BuyBackAmount)
	GROUP BY Bettype, CurrencyID

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

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptBetting_BA_CheckData', 
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