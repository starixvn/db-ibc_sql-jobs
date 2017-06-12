USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptBettingBySport_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rptBettingBySport
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source
	(
		SiteID				INT,
		CurrencyId			INT,
		StatusId			SMALLINT,
		LicenseeWL			MONEY,
		CustomerWL			MONEY,
		Turnover			MONEY,
		BetCount			INT,
		CommissionS			MONEY,
		CommShare			MONEY,
		CustomerCategory	INT
	);

	CREATE TABLE #Target
	(
		SiteID				INT,
		CurrencyId			INT,
		StatusId			SMALLINT,
		LicenseeWL			MONEY,
		CustomerWL			MONEY,
		Turnover			MONEY,
		BetCount			INT,
		CommissionS			MONEY,
		CommShare			MONEY,
		CustomerCategory	INT
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	INSERT INTO #Source(SiteID, CurrencyId, StatusId, LicenseeWL, CustomerWL,
						Turnover, BetCount, CommissionS, CommShare, CustomerCategory)
	SELECT	ISNULL(siteT.SiteID,-1) AS SiteID,
			b.currency AS CurrencyId,
			b.statusid AS StatusId,
			CASE ISNULL(l.LabelID,0) 
				WHEN 0 THEN 0
				ELSE SUM(actual_stake - winlost - swinlost - mwinlost -  awinlost - scomm)
			END AS LicenseeWL,
			SUM(winlost - actual_stake) AS CustomerWL, -- Customer Winlosss
			SUM(stake) AS Turnover, --Turnover
			COUNT(1) AS BetCount, --Total Bets
			-SUM(scomm) AS CommissionS, -- Commission for Licensee
			-SUM(scomm * 0.03/(1 - tpositiontaking)) AS CommShare, -- Commission for Licensee share with Muay Thai partner
			b.customercategory AS CustomerCategory
	FROM dbo.bettrans b with (nolock)
		INNER JOIN (
			SELECT matchid 
			FROM dbo.match WITH (NOLOCK) 
			WHERE SportType = 44
		) m ON b.matchid = m.matchid
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
		LEFT JOIN bodb_Licensee.dbo.Labels l WITH (NOLOCK) ON SiteT.SiteID = l.LabelID
	GROUP BY ISNULL(siteT.SiteID, -1), b.currency, b.statusid, b.customercategory, l.LabelID;

	SET @S_Count = @@ROWCOUNT;

	INSERT INTO #Target(SiteID, CurrencyId, StatusId, CustomerCategory, LicenseeWL, CustomerWL,
						Turnover, BetCount, CommissionS, CommShare)
	SELECT	SiteID, CurrencyId, StatusId, CustomerCategory, 
			LicenseeWL, CustomerWL,
			Turnover, BetCount, 
			CommissionS, CommShare
	FROM dbo.rpt_BettingBySport WITH(NOLOCK)
	WHERE rptDate = @WinlostDate;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX))

	INSERT INTO #Log(TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	'staging bettrans', 1, CurrencyID, SUM(Turnover), SUM(CustomerWL), SUM(BetCount),
			(
				SELECT	SUM(LicenseeWL) AS LicWL, SUM(CommissionS) AS CommS, SUM(CommShare) AS CommShare
				FROM #Source s1
				WHERE s1.CurrencyId = s.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.SiteID = t.SiteID AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId AND s.LicenseeWL = t.LicenseeWL
			AND s.CustomerWL = t.CustomerWL AND s.Turnover = t.Turnover AND s.BetCount = t.BetCount
			AND s.CommissionS = t.CommissionS AND s.CommShare = t.CommShare AND s.CustomerCategory = t.CustomerCategory)
	GROUP BY CurrencyId
	
	UNION ALL
	
	SELECT 'rpt_BettingBySport', 0, CurrencyID, SUM(Turnover), SUM(CustomerWL), SUM(BetCount),
			(
				SELECT	SUM(LicenseeWL) AS LicWL, SUM(CommissionS) AS CommS, SUM(CommShare) AS CommShare
				FROM #Target t1
				WHERE t1.CurrencyId = t.CurrencyId
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.SiteID = t.SiteID AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId AND s.LicenseeWL = t.LicenseeWL
			AND s.CustomerWL = t.CustomerWL AND s.Turnover = t.Turnover AND s.BetCount = t.BetCount
			AND s.CommissionS = t.CommissionS AND s.CommShare = t.CommShare AND s.CustomerCategory = t.CustomerCategory)
	GROUP BY CurrencyId;

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
			'Task_rptBettingBySport_CheckData', 
			TableName, 
			IsSource,
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