/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptThirdPartyWL_ExtraGMT_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT, --0: No mismatch; 1: Has real currencies; 2: UUS only
	@BetTypes			VARCHAR(MAX) OUTPUT
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rpt_ThirdPartyWL_ExtraGMT
	DB: DBLIC-bodb_LicenseeReport, DBBAL-bodb_LicenseeReport
	Original:
	Revisions:
		- 20181210@bruce: check Pragmatic data [#105723]
		- 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
	    - 20200508@Parsons: Integrate Sexy Gaming for deposit licensees [RedmineID: #132665]
	    - 20200615@Parsons: SA gaming report (GMT+8) [#134452]
		- 20200714@Parsons: Implement PP Jackpot [RedmineID: #137306]
		- 20201021@Parsons: Integrate WM Live Casino [#141357]
		- 20210113@Parsons: Provide timezone filter for Joker Games Win Loss Report [#148617]
		- 20210412@Sophia: Integrate PP Live Casino [Redmine: #150971]
		- 20210419@Danny: Integrate Creative Gaming [Redmine: #146019]
		- 20210412@Sophia: Change Range of AE Casino [Redmine :#152141]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211216@Danny: Get bettype from SportBettypeMaxtrix dynamically  [Redmine: #166158]
		- 20220110@Danny: SG - Jackpot prize integration [#167089]
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source
	(
		TableName				VARCHAR(100),
		RptDate3rd				DATE,
		SiteId					INT,
		BetTypeId				INT,
		CurrencyId				INT,
		StatusId				INT,
		BetCount				INT,
		Turnover				MONEY,
		Winloss					MONEY,
		AComm					MONEY,
		PComm					MONEY,
		AWinloss				MONEY,
		ProgressiveContribution	MONEY,
		ProgressivePayout		MONEY,
		ValidBetAmount			MONEY
	);

	CREATE TABLE #Target
	(
		RptDate3rd				DATE,
		SiteId					INT,
		BetTypeId				INT,
		CurrencyId				INT,
		StatusId				INT,
		BetCount				INT,
		Turnover				MONEY,
		Winloss					MONEY,
		AComm					MONEY,
		PComm					MONEY,
		AWinloss				MONEY,
		ProgressiveContribution	MONEY,
		ProgressivePayout		MONEY,
		ValidBetAmount			MONEY
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	DECLARE @RnGBettypeList TABLE(Bettype INT)
	INSERT INTO @RnGBettypeList(Bettype)
	SELECT	DISTINCT bettype
	FROM	bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'FW,PP,CC,SG,JK,CG') la		

	DECLARE @LCBettypeList TABLE(Bettype INT)
	INSERT INTO @LCBettypeList(Bettype)
	SELECT	DISTINCT bettype
	FROM	bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'AB,SXG,SAG,WM,PPL') la

	INSERT INTO #Source(TableName, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, AWinloss, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
	(
		SELECT	'bettransRnG14',
				CAST(b.Transdate3rd AS DATE)	AS RptDate3rd,
				ISNULL(site.SiteID, -1) AS siteid,
				b.gameID	 AS BetTypeId,
				b.currency,
				b.statusID,
				ISNULL(COUNT(1), 0) AS BetCount,
				ISNULL(SUM(ABS(b.stake)), 0) AS Turnover,
				ISNULL(SUM(winlost - actual_stake), 0) AS Winloss,
				ISNULL(SUM(b.comm), 0) AS AComm,
				ISNULL(SUM(b.playercomm), 0) AS PComm,
				ISNULL(SUM(b.awinlost), 0) AS AWinloss,
				ISNULL(SUM(CASE WHEN b.gameID IN (4297, 4599) THEN ContributionStake3rd ELSE 0 END), 0) AS ProgressiveContribution, -- Full Contribution(PP-4297)
				ISNULL(SUM(ISNULL(p.WinAmount,0)), 0) AS ProgressivePayout,
				0 AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG14 b WITH (NOLOCK)
			LEFT JOIN DBTXN.bodb02.dbo.PayoutTrans p ON b.transid = p.RefNo			
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.gameID IN (SELECT x.Bettype FROM @RnGBettypeList x)
		GROUP BY CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID,
			b.currency, b.statusID	
			
		UNION ALL

		SELECT	'bettransLC14',
				CAST(b.Transdate3rd AS DATE)	AS RptDate3rd,
				ISNULL(site.SiteID, -1) AS siteid,
				b.gameID AS BetTypeId,
				b.currency,
				b.statusID,
				ISNULL(COUNT(1), 0) AS BetCount,
				ISNULL(SUM(ABS(b.stake)), 0) AS Turnover,
				ISNULL(SUM(winlost - actual_stake), 0) AS Winloss,
				ISNULL(SUM(b.comm), 0) AS AComm,
				ISNULL(SUM(b.playercomm), 0) AS PComm,
				ISNULL(SUM(b.awinlost), 0) AS AWinloss,
				0 AS ProgressiveContribution,
				0 AS ProgressivePayout,
				ISNULL(SUM(ISNULL(b.NetStake, 0)), 0) AS ValidBetAmount
		FROM bodb02.dbo.bettransLC14 b WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.gameID IN (SELECT x.Bettype FROM @LCBettypeList x)
		GROUP BY CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID,
			b.currency, b.statusID	
	);

	SET @S_Count = @@ROWCOUNT;
	
	INSERT INTO #Target(RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, AWinloss, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
	SELECT	RptDate3rd,
			SiteId,
			BetTypeId,
			CurrencyId,
			StatusId,
			ISNULL(SUM(BetCount), 0),
			ISNULL(SUM(Turnover), 0),
			ISNULL(SUM(Winloss), 0),
			ISNULL(SUM(AComm), 0),
			ISNULL(SUM(PComm), 0),
			ISNULL(SUM(AWinloss), 0),
			ISNULL(SUM(ProgressiveContribution), 0),
			ISNULL(SUM(ProgressivePayout), 0),
			ISNULL(SUM(ValidBetAmount), 0)
	FROM dbo.rpt_ThirdPartyWL_ExtraGMT WITH(NOLOCK)
	WHERE RptDate = @WinlostDate
	GROUP BY RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, BetTypeId INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	TableName, 1, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount),
			(
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(AWinloss) AS AWinloss, SUM(ProgressiveContribution) AS ProgContrib,
						SUM(ProgressivePayout) AS ProgPayout, SUM(ValidBetAmount) AS ValidBetAmt
				FROM #Source s1
				WHERE s1.TableName = s.TableName
					AND s1.BetTypeId = s.BetTypeId
					AND s1.CurrencyId = s.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.RptDate3rd = t.RptDate3rd AND s.SiteId = t.SiteId AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId
			AND s.StatusId = t.StatusId AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.AWinloss = t.AWinloss AND s.ProgressiveContribution = t.ProgressiveContribution
			AND s.ProgressivePayout = t.ProgressivePayout AND s.ValidBetAmount = t.ValidBetAmount)
	GROUP BY TableName, BetTypeId, CurrencyId
			
	UNION ALL
	
	SELECT 'rpt_ThirdPartyWL_ExtraGMT', 0, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount),
			(
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(AWinloss) AS AWinloss, SUM(ProgressiveContribution) AS ProgContrib,
						SUM(ProgressivePayout) AS ProgPayout, SUM(ValidBetAmount) AS ValidBetAmt
				FROM #Target t1
				WHERE t1.BetTypeId = t.BetTypeId
					AND t1.CurrencyId = t.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.RptDate3rd = t.RptDate3rd AND s.SiteId = t.SiteId AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId
			AND s.StatusId = t.StatusId AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.AWinloss = t.AWinloss AND s.ProgressiveContribution = t.ProgressiveContribution
			AND s.ProgressivePayout = t.ProgressivePayout AND s.ValidBetAmount = t.ValidBetAmount)
	GROUP BY BetTypeId, CurrencyId;

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

	SELECT @BetTypes = STUFF(
			(
				SELECT DISTINCT ', ' + CAST(BetTypeId AS VARCHAR(10))
				FROM #Log
				FOR XML PATH('')
			), 1, 2, ''
		);

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptThirdPartyWL_ExtraGMT_CheckData', 
			TableName, 
			IsSource,
			BetTypeId,
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log;

	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END