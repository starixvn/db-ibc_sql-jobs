USE [bodb_Report]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_MicroGaming_BettransBK] 
	@FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
AS
/*   
	Creator: 20150731@Florent
	Task: Gen history data for Microgaming Casino from bettrans_bk
	DB: DBRPT/bodb_report
	Revisions: 	
	- 20160422@Francis: add Progressive Contribution and Progressive Payout for Microgaming RNG
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN

	--clean data from temp table
	DELETE FROM dbo.rpt_ThirdPartyWL_ExtraGMT WITH(ROWLOCK)
	WHERE rptDate BETWEEN @FromDate AND @ToDate

	DECLARE @WinlostDate DATE
	SELECT	@WinlostDate = @FromDate

	DECLARE @Sitelist AS TABLE (IbcSiteID INT, SiteID INT)	
	INSERT INTO @Sitelist (IbcSiteID, SiteID)
	SELECT IbcSiteID, SiteID
	FROM OPENQUERY(DBLIC, 'SELECT IbcSiteID, SiteID FROM bodb_Licensee.dbo.view_site_list')	
	
	DECLARE @ContributionRate AS TABLE (ResourceID INT, Contribution MONEY)	
	INSERT INTO @ContributionRate (ResourceID, Contribution)
	SELECT ResourceID, Contribution
	FROM OPENQUERY(DBLIC, 'SELECT ResourceID, Contribution FROM bodb_LicenseeReport.dbo.view_MGCRNG_ProgressiveContribution_Rate')	

	--bettype mapping
	DECLARE @Bettype AS TABLE(Bettype INT)
    INSERT INTO @Bettype (Bettype)
    SELECT Bettype
    FROM OPENQUERY(DBLIC, 'SELECT Bettype FROM bodb_Licensee.dbo.Sport_Bettype_Reference WITH (NOLOCK) WHERE Sporttype = 203')

	WHILE @WinlostDate <= @ToDate
	BEGIN
		INSERT INTO dbo.rpt_ThirdPartyWL_ExtraGMT(RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout)
		(SELECT CAST(b.winlostdate AS DATE)	AS Rptdate
			, CAST(b.checktime AS DATE)	AS RptDate3rd
			, ISNULL(site.SiteID, -1) AS siteid
			, b.bettype	 AS BetTypeId		
			, b.currency
			, b.statusID
			, COUNT(1) AS BetCount
			, SUM(ABS(b.stake)) AS Turnover
			, SUM(winlost - actual_stake) AS Winloss		
			, SUM(b.comm) AS AComm
			, SUM(b.playercomm) AS PComm
			, 0 AS ProgressiveContribution
			, 0 AS ProgressivePayout		
		FROM bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK)
			INNER JOIN @Bettype bt ON b.bettype = bt.Bettype
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN @Sitelist [site] ON s.siteid = site.IbcSiteID
		WHERE b.winlostdate = @Winlostdate		
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.checktime AS DATE), ISNULL(site.SiteID,-1), b.bettype
		, b.currency, b.statusID
		UNION ALL
 
		SELECT CAST(b.winlostdate AS DATE)	AS Rptdate
			, CAST(b.Transdate3rd AS DATE)	AS RptDate3rd
			, ISNULL(site.SiteID, -1) AS siteid
			, b.gameID	 AS BetTypeId		
			, b.currency
			, b.statusID
			, COUNT(1) AS BetCount
			, SUM(ABS(b.stake)) AS Turnover
			, SUM(winlost - actual_stake) AS Winloss		
			, SUM(b.comm) AS AComm
			, SUM(b.playercomm) AS PComm
			, SUM(ISNULL(ABS(b.stake) * r.Contribution,0)) AS ProgressiveContribution
			, SUM(ISNULL(WinAmount,0)) AS ProgressivePayout
		FROM bodb_Archive.dbo.bettransRnG_bk b WITH (NOLOCK)
			LEFT JOIN @ContributionRate r ON b.transdesc = r.ResourceID
			LEFT JOIN DBTXN.bodb02.dbo.PayoutTrans p ON b.transid = p.RefNo			
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
			LEFT JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
			LEFT JOIN @Sitelist [site] ON s.siteid = site.IbcSiteID			
		WHERE b.winlostdate = @Winlostdate
			AND b.statusID NOT IN (0, 1, 101, 102, 121)
			AND b.gameID IN (2008, 2009)
		GROUP BY CAST(b.winlostdate AS DATE), CAST(b.Transdate3rd AS DATE), ISNULL(site.SiteID, -1), b.gameID
			, b.currency, b.statusID		
		)
		OPTION (MAXDOP 1)
	
		--reset params		
		SET @WinlostDate = DATEADD(D, 1, @WinlostDate)

		WAITFOR DELAY '00:00:00.280'
	
	END		
	
	--GEN DATA TO DBLIC
	SET	@WinlostDate = @FromDate
	
	WHILE (@Winlostdate <= @Todate)
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.rpt_ThirdPartyWL_ExtraGMT WITH (NOLOCK) WHERE RptDate = @Winlostdate)
		BEGIN
			DELETE DB054.bodb_LicenseeReport.dbo.rpt_ThirdPartyWL_ExtraGMT WITH (ROWLOCK, UPDLOCK) WHERE RptDate = @Winlostdate
		END
		
		INSERT INTO DB054.bodb_LicenseeReport.dbo.rpt_ThirdPartyWL_ExtraGMT (RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout)
			SELECT RptDate, RptDate3rd, SiteId, BetTypeId, CurrencyId, StatusId, BetCount, Turnover, Winloss, AComm, PComm, ProgressiveContribution, ProgressivePayout
			FROM dbo.rpt_ThirdPartyWL_ExtraGMT
			WHERE rptDate = @WinlostDate
		--reset params		
		SET @WinlostDate = DATEADD(D, 1, @WinlostDate)
	END
END
GO
GRANT EXECUTE ON [dbo].[Task_MicroGaming_BettransBK] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_MicroGaming_BettransBK] TO [vnteam] AS [dbo]