ALTER PROCEDURE [dbo].[DELETED_GEN_rptBetting_DepositSites]
    @date datetime, 
    @date2 datetime = null
AS
/*
Created: 20111201@Don
Task: Generate data of deposit sites into rpt_Betting 
DB: DB052.bodb_Licensee

Revisions:
	20131104@Jim: move table rpt_betting to bodb_LicenseeReport DB	
Param's Explanation:

*/
IF @date2 IS NULL SET @date2 = @date
SET @date2 = DATEADD(day,1,@date2)

DELETE b 
FROM bodb_LicenseeReport.dbo.rpt_Betting b
    INNER JOIN dbo.Licensees lic (NOLOCK) ON b.SiteID=lic.LicenseeID AND lic.IsDeposit=1
WHERE rptDate>=@date AND rptDate<@date2

INSERT INTO bodb_LicenseeReport.dbo.rpt_Betting
    SELECT  
	    b.winlostdate,
        ISNULL(site.SiteID,-1) siteid,
	    b.bettype,
        CASE 
            WHEN b.bettype=9 THEN -9 
            WHEN (b.bettype=10) OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
            ELSE ISNULL(m.leagueid,-1) 
        END AS leagueid,	
	    b.currency,
	    ISNULL(sta.statusid,-1) [Status],
	    b.liveindicator,
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
	    b.customercategory
    FROM
	    dbo.bettrans b (NOLOCK) 
	    LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
	    LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
	    LEFT JOIN dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID	
	    LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
	    LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
	    LEFT JOIN dbo.view_status_list sta (NOLOCK) ON b.Status = sta.StatusName
    WHERE isBA=0
    GROUP BY
	    b.winlostdate,
	    ISNULL(site.SiteID,-1),
	    b.bettype,
        CASE 
            WHEN b.bettype=9 THEN -9 
            WHEN (b.bettype=10) OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
            ELSE ISNULL(m.leagueid,-1) 
        END,	
	    b.currency,
	    ISNULL(sta.statusid,-1),
	    b.liveindicator,
	    b.customercategory

--update MTD table
EXEC dbo.GEN_RptKPI_MTD_DepositSites
    @date = @date, 
    @date2 = @date2,
    @stattype = 2,
    @isBA = 0
    
GO
GRANT EXECUTE ON [dbo].[GEN_rptBetting_DepositSites] TO [VNTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptBetting_DepositSites] TO [VNTeam]