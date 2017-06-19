USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptKenoWinloss_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rptKenoWinloss
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source 
	(
		SiteId			INT,
		BetTypeId		INT,
		CurrencyId		INT,
		StatusId		INT,
		BetCount		INT,
		Turnover		MONEY,
		Winloss			MONEY
	);

	CREATE TABLE #Target 
	(
		SiteId			INT,
		BetTypeId		INT,
		CurrencyId		INT,
		StatusId		INT,
		BetCount		INT,
		Turnover		MONEY,
		Winloss			MONEY
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	CREATE TABLE #Bettype (Bettype INT);

    INSERT INTO #Bettype(Bettype)
    SELECT Bettype
	FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, 'KN');

	INSERT INTO #Source(SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss)
	SELECT	ISNULL(site.SiteID, -1) AS SiteId,
			b.bettype AS BetTypeId,
			b.currency,
			b.statusID,
			ISNULL(COUNT(1), 0) AS BetCount,
			ISNULL(SUM(ABS(b.stake)), 0) AS Turnover,
			ISNULL(SUM(winlost - actual_stake), 0) AS Winloss		
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN #Bettype bt ON b.bettype = bt.Bettype
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID	
	WHERE b.winlostdate = @WinlostDate		
		AND b.statusID NOT IN (0, 1, 101, 102, 121)
	GROUP BY ISNULL(site.SiteID, -1), b.bettype, b.currency, b.statusID;

	SET @S_Count = @@ROWCOUNT;

	INSERT INTO #Target(SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss)
	SELECT	SiteId,
			BetTypeId,
			CurrencyId,
			StatusId,
			ISNULL(SUM(BetCount), 0),
			ISNULL(SUM(Turnover), 0),
			ISNULL(SUM(Winloss), 0)
	FROM dbo.rptKenoWinloss WITH(NOLOCK)
	WHERE RptDate = @WinlostDate
	GROUP BY SiteId, BetTypeId, CurrencyId, StatusId;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, BetTypeId INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT);

	INSERT INTO #Log(TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount)
	SELECT 'bettrans14', 1, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount)
	FROM #Source s
	WHERE NOT EXISTS ( 
		SELECT 1 
		FROM #Target t 
		WHERE s.SiteId = t.SiteId AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId
			AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss)
	GROUP BY BetTypeId, CurrencyId

	UNION ALL

	SELECT 'rptKenoWinloss', 0, BetTypeId, CurrencyId, SUM(Turnover), SUM(Winloss), SUM(BetCount)
	FROM #Target t
	WHERE NOT EXISTS ( 
		SELECT 1 
		FROM #Source s
		WHERE s.SiteId = t.SiteId AND s.BetTypeId = t.BetTypeId AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId
			AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss)
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

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount)
	SELECT	@WinlostDate, 
			'Task_rptKenoWinloss_CheckData', 
			TableName, 
			IsSource,
			BetTypeId,
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount
	FROM #Log;

	DROP TABLE #Bettype;
	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END