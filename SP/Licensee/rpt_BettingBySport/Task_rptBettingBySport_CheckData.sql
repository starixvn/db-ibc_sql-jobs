USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptBettingBySport_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	BIT OUTPUT
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
	SELECT	TOP(@S_Count + 1) SiteID, CurrencyId, StatusId, CustomerCategory, 
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

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1;

		RETURN;
	END
	
	SELECT TOP(1) @i = 1
	FROM #Source s
	WHERE NOT EXISTS(
		SELECT 1
		FROM #Target t
		WHERE s.SiteID = t.SiteID AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId AND s.LicenseeWL = t.LicenseeWL
			AND s.CustomerWL = t.CustomerWL AND s.Turnover = t.Turnover AND s.BetCount = t.BetCount
			AND s.CommissionS = t.CommissionS AND s.CommShare = t.CommShare AND s.CustomerCategory = t.CustomerCategory);

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 1
	BEGIN
		SET @HasDataMismatch = 1;
	END

	SET NOCOUNT OFF;
END