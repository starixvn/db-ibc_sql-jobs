USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_rptBettingBySport]
    @FromDate smalldatetime,
    @ToDate smalldatetime = NULL
AS
/*
    Created: 20150226@Francis
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DB052.bodb_LicenseeReport

    Revisions:

*/ 

    IF @ToDate IS NULL SET @ToDate = @FromDate
	SET @ToDate = DATEADD(day,1,@ToDate)

	DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate >= @FromDate AND rptDate < @ToDate
	
	
	--For Muay Thai
	INSERT INTO dbo.rpt_BettingBySport(rptDate 
									   , SiteID 
									   , ProductID
									   , SportType 
									   , CurrencyId
									   , StatusId
									   , CustomerWL
									   , Turnover
									   , BetCount
									   , WLShare
									   , CommissionS
									   , CommShare
									   , CustomerCategory)							   																	   
	SELECT	b.winlostdate AS rptDate
			, isnull(siteT.SiteID,-1) AS SiteID
			, 0 AS ProductID
			, 44 AS SportType
			, b.currency AS CurrencyId
			, b.statusid AS StatusId
			, sum(winlost - actual_stake) AS CustomerWL -- Customer Winlosss
			, sum (stake) AS Turnover --Turnover
			, count (1) AS BetCount --Total Bets
			, sum(actual_stake - winlost) * 0.03 as WLShare -- Winloss Share with Muay Thai partner
			, sum(scomm) as CommissionS -- Commission for Licensee
			, sum(scomm * 0.03/(1 - tpositiontaking)) as CommShare -- Commission for Licensee share with Muay Thai partner
			, b.customercategory AS CustomerCategory
	FROM bodb_Licensee.dbo.bettrans b with (nolock)
		INNER JOIN (SELECT matchid FROM bodb02.dbo.match WITH (NOLOCK) WHERE eventdate BETWEEN @fromdate AND @todate AND SportType = 44) m ON b.matchid = m.matchid
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN DBLIC.bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid=siteT.IbcSiteID
	WHERE b.winlostdate between @fromdate and @todate
	GROUP BY b.winlostdate, isnull(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory  
   


GO

GRANT EXECUTE ON [dbo].[GEN_rptBettingBySport] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[GEN_rptBettingBySport] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[GEN_rptBettingBySport] TO [vnteam] AS [dbo]
GO


