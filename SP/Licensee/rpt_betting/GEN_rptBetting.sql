USE bodb_Licensee
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GEN_rptBetting    Script Date: 12/14/2015 5:04:57 PM ******/
 
ALTER PROCEDURE [dbo].[GEN_rptBetting]
    @date datetime, 
    @date2 datetime = null
AS


/*
Created: 20110517@Elly
Task: Generate data into rpt_Betting 
DB: DB052.bodb_Licensee

Revisions:
	20110708@Elly: Process data of Fee and Comm
	20110726@Daniel: Process Non-BA data only
	20111115@Don: Add information to identify 8RM (customercategory=27)
	20121102@Jim: add process to generate data for KPI NumberGame report
	20130903@Jim: support Virtual Horse Racing
	20150623@Patrick: Support BetTrade
	20150917@Francis: Cast LiveIndicator to 0 if it is NULL
	20151119@Jim: separate MicroGame into 2 product (#46454 )
	20160106@Bobby: add OneRnG Casino

Param's Explanation:

*/
IF @date2 IS NULL SET @date2 = @date
SET @date2 = DATEADD(day,1,@date2)

DELETE FROM dbo.rpt_Betting
WHERE rptDate>=@date AND rptDate<@date2

INSERT INTO dbo.rpt_Betting
        ([rptDate]
        ,[SiteID]
        ,[Bettype]
        ,[LeagueID]
        ,[CurrencyID]
        ,[Status]
        ,[IsLive]
        ,[BetCount]
        ,[MemberCount]
        ,[Turnover]
        ,[WinLoss]
        ,[WinLossA]
        ,[WinLossM]
        ,[WinLossS]
        ,[CommissionP]
        ,[CommissionA]
        ,[CommissionM]
        ,[CommissionS]
        ,[WinLossVirtual]
        ,[CommissionSVirtual]
        ,[CustomerCategory]
		,[BuyBackAmount])
    SELECT  
	    b.winlostdate,
        ISNULL(site.SiteID,-1) siteid,
	    b.bettype,
        CASE 
            WHEN b.bettype=9 THEN -9 
            WHEN b.bettype = 10 OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)
            WHEN b.bettype IN(1231,1232,1233,1237,1238) THEN RaceInfo.LeagueID
            ELSE ISNULL(m.leagueid,-1) 
        END AS leagueid,
	    b.currency,
	    b.statusid Status,
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
	    SUM((winlost-actual_stake)*virtualrate) WinLossVirtual,
	    SUM(scomm*virtualrate) CommissionSVirtual,
	    b.customercategory,
		SUM(CASE WHEN b.bettype IN (901) THEN winlost ELSE 0 END)
    FROM
	    dbo.bettrans b (NOLOCK) 
	    LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
	    LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
	    LEFT JOIN dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	    LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
	    LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
	    LEFT JOIN DBRPT.bodb02.dbo.VSRaceInfo RaceInfo WITH (NOLOCK) ON b.matchid = RaceInfo.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
    WHERE isBA=0
    GROUP BY
	    b.winlostdate,
	    ISNULL(site.SiteID,-1),
	    b.bettype,
        CASE 
            WHEN b.bettype=9 THEN -9 
            WHEN b.bettype = 10 OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
            WHEN b.bettype IN(1231,1232,1233,1237,1238) THEN RaceInfo.LeagueID
            ELSE ISNULL(m.leagueid,-1) 
        END,	
	    b.currency,
	    b.statusid,
	    b.liveindicator,
	    b.customercategory
 
	SELECT  
	    b.winlostdate,
        ISNULL(site.SiteID,-1) siteid,
	    b.gameID AS bettype,
        b.currency,
	    
	    SUM(betcount) Betcount 
	    INTO #bRnG
	FROM
			(	SELECT COUNT(b.transid) betcount
					   ,b.winlostdate
					   , b.gameID
					   , b.currency
						,b.recommend
			FROM bodb02.dbo.bettransRNG b (NOLOCK) 
				WHERE b.winlostdate BETWEEN @date AND @date2
					AND b.IsSum=1
					--AND b.gameID IN (2008,2009)
			GROUP BY   b.winlostdate
					   ,b.gameID
					   ,b.currency
					   ,b.recommend 
							
				UNION ALL
				SELECT COUNT(b1.transid) betcount
					   ,b1.winlostdate
					   , b1.gameID
					   , b1.currency
						,b1.recommend
				FROM bodb02.dbo.bettransRNG14 b1 (NOLOCK) 
				WHERE b1.winlostdate BETWEEN @date AND @date2
					AND b1.IsSum=1
					--AND b1.gameID IN (2008,2009) 
				GROUP BY  b1.winlostdate
						  ,b1.gameID
					      ,b1.currency
						  ,b1.recommend	
			)b
			LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
	        LEFT JOIN dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	GROUP BY
		   b.winlostdate,
			ISNULL(site.SiteID,-1)  ,
			b.gameID,
			b.currency  
	 
UPDATE 	rpt_Betting  
SET BetCount= bRnG.BetCount
FROM dbo.rpt_Betting b WITH (NOLOCK)
	INNER JOIN #bRnG bRnG ON b.rptDate= bRnG.winlostdate
								AND b.siteid= bRnG.siteid	
								AND b.Bettype = bRnG.bettype
								AND b.CurrencyID = bRnG.currency
								 
DROP TABLE #bRnG
--update MTD table
EXEC dbo.GEN_RptKPI_MTD_Betting
    @date = @date, 
    @date2 = @date2,
    @isBA = 0
--update KPI NumberGame
exec GEN_RptKPI_MTD_Betting_3rdproduct
    @date = @date, 
    @date2 = @date2    
    
/*EXEC [dbo].[GEN_RptKPI_MTD]
    @date = @date, 
    @date2 = @date2,
    @stattype = 2,
    @isBA = 0*/




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[GEN_rptBetting] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[GEN_rptBetting] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[GEN_rptBetting] TO [bodbLicenseeNet]
GO 
