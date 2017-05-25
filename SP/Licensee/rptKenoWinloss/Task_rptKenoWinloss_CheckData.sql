USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptKenoWinloss_CheckData]
	@WinlostDate SMALLDATETIME,
	@HasDataMismatch BIT = 0 OUTPUT
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

	CREATE TABLE #Source 
	(
		RptDate			DATE,
		SiteId			INT,
		BetTypeId		INT,
		KenoBetTypeId	INT,
		ChoiceId		INT,
		CurrencyId		INT,
		StatusId		INT,
		BetCount		INT,
		Turnover		MONEY,
		Winloss			MONEY
	);

	CREATE TABLE #Target 
	(
		RptDate			DATE,
		SiteId			INT,
		BetTypeId		INT,
		KenoBetTypeId	INT,
		ChoiceId		INT,
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

	INSERT INTO #Source(RptDate, SiteId, BetTypeId, KenoBetTypeId, ChoiceId, CurrencyId, StatusId, BetCount, Turnover, Winloss)
	SELECT	CAST(b.winlostdate AS DATE)	AS Rptdate,
			ISNULL(site.SiteID, -1) AS SiteId,
			b.bettype AS BetTypeId,
			ISNULL(v.BettypeID, -1) AS KenoBetTypeId,
			p.ChoiceId AS ChoiceId,
			b.currency,
			b.statusID,
			COUNT(1) AS BetCount,
			SUM(ABS(b.stake)) AS Turnover,
			SUM(winlost - actual_stake) AS Winloss		
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN #Bettype bt ON b.bettype = bt.Bettype
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID	
		CROSS APPLY bodb02.dbo.f_ParseTransDesc(b.transdesc, b.bettype) p
		LEFT JOIN bodb02.dbo.View_KenoBettypeMapping v ON p.ChoiceId = v.ChoiceId
	WHERE b.winlostdate = @WinlostDate		
		AND b.statusID NOT IN (0, 1, 101, 102, 121)
	GROUP BY CAST(b.winlostdate AS DATE), ISNULL(site.SiteID, -1), b.bettype,
		p.ChoiceId, ISNULL(v.BettypeID, -1),  b.currency, b.statusID;

	SET @S_Count = @@ROWCOUNT;

	INSERT INTO #Target(RptDate, SiteId, BetTypeId, KenoBetTypeId, ChoiceId, CurrencyId, StatusId, BetCount, Turnover, Winloss)
	SELECT	TOP(@S_Count + 1) RptDate,
			SiteId,
			BetTypeId,
			KenoBetTypeId,
			ChoiceId,
			CurrencyId,
			StatusId,
			BetCount,
			Turnover,
			Winloss
	FROM dbo.rptKenoWinloss WITH(NOLOCK)
	WHERE RptDate = @WinlostDate;

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

	SELECT TOP(@S_Count + 1) @i = 1
	FROM #Source s
		FULL OUTER JOIN #Target t 
			ON s.SiteId = t.SiteId AND s.BetTypeId = t.BetTypeId AND s.KenoBetTypeId = t.KenoBetTypeId 
				AND s.ChoiceId = t.ChoiceId AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId
				AND s.BetCount = t.BetCount AND s.Turnover = t.Turnover AND s.Winloss = t.Winloss
	
	SET @T_Count = @@ROWCOUNT;

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1;
	END

	SET NOCOUNT OFF;
END