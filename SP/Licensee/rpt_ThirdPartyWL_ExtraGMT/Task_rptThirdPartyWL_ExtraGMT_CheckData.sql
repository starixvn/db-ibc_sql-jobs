USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptThirdPartyWL_ExtraGMT_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rpt_ThirdPartyWL_ExtraGMT
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
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
		ProgressiveContribution	MONEY,
		ProgressivePayout		MONEY,
		ValidBetAmount			MONEY
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	DECLARE @Bettype AS TABLE(Bettype INT);

    INSERT INTO @Bettype(Bettype)
    SELECT Bettype
	FROM bodb_licensee.dbo.Sport_Bettype_Reference WITH (NOLOCK)
	WHERE Sporttype IN (203, 205);

	INSERT INTO #Source(TableName, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
	(
		SELECT	'bettrans14',
				CAST(b.checktime AS DATE) AS RptDate3rd,
				ISNULL(site.SiteID, -1) AS siteid,
				b.bettype AS BetTypeId,
				b.currency,
				b.statusID,
				COUNT(1) AS BetCount,
				SUM(ABS(b.stake)) AS Turnover,
				SUM(winlost - actual_stake) AS Winloss,
				SUM(b.comm) AS AComm,
				SUM(b.playercomm) AS PComm,
				0 AS ProgressiveContribution,
				0 AS ProgressivePayout,
				0 AS ValidBetAmount	
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN @Bettype bt ON b.bettype = bt.Bettype
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID
		WHERE b.winlostdate = @WinlostDate	
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.bettype NOT IN (2008, 2009)
			AND b.bettype NOT BETWEEN 1011 AND 1020
		GROUP BY CAST(b.checktime AS DATE), ISNULL(site.SiteID,-1), b.bettype,
			b.currency, b.statusID

		UNION ALL
 
		SELECT	'bettransRnG14',
				CAST(b.Transdate3rd AS DATE)	AS RptDate3rd,
				ISNULL(site.SiteID, -1) AS siteid,
				b.gameID	 AS BetTypeId,
				b.currency,
				b.statusID,
				COUNT(1) AS BetCount,
				SUM(ABS(b.stake)) AS Turnover,
				SUM(winlost - actual_stake) AS Winloss,
				SUM(b.comm) AS AComm,
				SUM(b.playercomm) AS PComm,
				SUM(ISNULL(ABS(b.stake) * r.Contribution,0)) AS ProgressiveContribution,
				SUM(ISNULL(p.WinAmount,0)) AS ProgressivePayout,
				0 AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG14 b WITH (NOLOCK)
			LEFT JOIN dbo.view_MGCRNG_ProgressiveContribution_Rate r ON b.transdesc = r.ResourceID
			LEFT JOIN DBTXN.bodb02.dbo.PayoutTrans p ON b.transid = p.RefNo			
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND ( b.gameID IN (2008, 2009)
				 OR b.gameID BETWEEN 1011 AND 1020
				 )
		GROUP BY CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID,
			b.currency, b.statusID	
			
		UNION ALL

		SELECT	'bettransLC14',
				CAST(b.Transdate3rd AS DATE)	AS RptDate3rd,
				ISNULL(site.SiteID, -1) AS siteid,
				b.gameID AS BetTypeId,
				b.currency,
				b.statusID,
				COUNT(1) AS BetCount,
				SUM(ABS(b.stake)) AS Turnover,
				SUM(winlost - actual_stake) AS Winloss,
				SUM(b.comm) AS AComm,
				SUM(b.playercomm) AS PComm,
				0 AS ProgressiveContribution,
				0 AS ProgressivePayout,
				SUM(ISNULL(b.NetStake, 0)) AS ValidBetAmount
		FROM bodb02.dbo.bettransLC14 b WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.gameID BETWEEN 2401 AND 2499
		GROUP BY CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID,
			b.currency, b.statusID	
	);

	SET @S_Count = @@ROWCOUNT;
	
	INSERT INTO #Target(RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout, ValidBetAmount)
	SELECT	RptDate3rd,
			SiteId,
			BetTypeId,
			CurrencyId,
			StatusId,
			SUM(BetCount),
			SUM(Turnover),
			SUM(Winloss),
			SUM(AComm),
			SUM(PComm),
			SUM(ProgressiveContribution),
			SUM(ProgressivePayout),
			SUM(ValidBetAmount)
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
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(ProgressiveContribution) AS ProgContrib,
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
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.ProgressiveContribution = t.ProgressiveContribution
			AND s.ProgressivePayout = t.ProgressivePayout AND s.ValidBetAmount = t.ValidBetAmount)
	GROUP BY TableName, BetTypeId, CurrencyId
			
	UNION ALL
	
	SELECT 'rpt_ThirdPartyWL_ExtraGMT', 0, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount),
			(
				SELECT	SUM(AComm) AS AComm, SUM(PComm) AS PComm, SUM(ProgressiveContribution) AS ProgContrib,
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
			AND s.AComm = t.AComm AND s.PComm = t.PComm AND s.ProgressiveContribution = t.ProgressiveContribution
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