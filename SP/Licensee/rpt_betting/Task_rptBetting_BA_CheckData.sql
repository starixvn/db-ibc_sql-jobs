/*<info serverAlias="DBLIC-bodb_LicenseeReport," executers="" viewers="vnteam" isFunction="0" isNested=”0”></info>*/
USE bodb_LicenseeReport
GO
ALTER PROCEDURE [dbo].[Task_rptBetting_BA_CheckData]
    @WinlostDate		datetime
	,@HasDataMismatch	BIT OUTPUT 
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
	  SELECT 	    
        ISNULL(site.SiteID,-1) siteid,
	    b.bettype,       
	    b.currency,
	    ISNULL(sta.statusid,-1) [Status],
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
		SUM(CASE WHEN b.bettype IN (901) THEN winlost ELSE 0 END) BuyBackAmount		
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
	    b.currency,
	    ISNULL(sta.statusid,-1),
	    b.customercategory


	SET @S_Count = @@ROWCOUNT


	INSERT INTO #Target (SiteID, Bettype, CurrencyID, Status, BetCount, MemberCount,	
						Turnover, WinLoss, WinLossA, WinLossM, WinLossS, 
						CommissionP, CommissionA, CommissionM, CommissionS,	CustomerCategory, 
						BuyBackAmount)
	SELECT	TOP(@S_Count + 1) SiteID, Bettype, CurrencyID, Status, SUM(BetCount), SUM(MemberCount),	
			SUM(Turnover), SUM(WinLoss), SUM(WinLossA), SUM(WinLossM), SUM(WinLossS), 
			SUM(CommissionP), SUM(CommissionA), SUM(CommissionM), SUM(CommissionS),	CustomerCategory, 
			SUM(BuyBackAmount)
	FROM dbo.rpt_betting_BA WITH (NOLOCK)
	WHERE RptDate = @WinlostDate 
	GROUP BY SiteID, Bettype, CurrencyID, Status, CustomerCategory
		   
	SET @T_Count = @@ROWCOUNT


	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN
	END

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1

		RETURN;
	END

	SELECT TOP(1) @i = 1
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t 
		WHERE s.SiteId = t.SiteId AND s.Bettype = t.Bettype AND s.CurrencyID = t.CurrencyID 
				AND s.Status = t.Status AND s.CustomerCategory = t.CustomerCategory AND s.BetCount = t.BetCount
				AND s.MemberCount = t.MemberCount AND s.Turnover = t.Turnover AND s.WinLoss = t.WinLoss
				AND s.WinLossA = t.WinLossA AND s.WinLossM = t.WinLossM AND s.WinLossS = t.WinLossS 
				AND s.CommissionP = t.CommissionP AND s.CommissionA = t.CommissionA AND s.CommissionM = t.CommissionM
				AND s.CommissionS = t.CommissionS AND s.BuyBackAmount = t.BuyBackAmount ) 
	
	SET @T_Count = @@ROWCOUNT

	IF @T_Count = 1
	BEGIN
		SET @HasDataMismatch = 1
	END
			
END 