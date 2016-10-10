ALTER PROCEDURE [dbo].[GEN_rptBetting_NegativeStake]
    @date datetime, 
    @date2 datetime = -1
AS
/*
Created: 20111118@Don
Task: Generate data into rpt_Betting (fix stake<0, bettype:[4,5,6,10,14,15,16], site:best-odds)
DB: DB052.bodb_Licensee

Revisions:
	-20131104@Jim: move table rpt_betting to bodb_LicenseeReport DB	
Param's Explanation:

*/
if @date2 = -1 set @date2 = @date
set @date2 = DATEADD(day,1,@date2)

DELETE FROM bodb_LicenseeReport.dbo.rpt_Betting
WHERE rptDate >= @date and rptdate < @date2
    and bettype in (4,5,6,10,14,15,16)
    and siteid in (1001,1013,1016)

INSERT INTO bodb_LicenseeReport.dbo.rpt_Betting
    SELECT  
	    b.winlostdate,
        isnull(site.SiteID,-1) siteid,
	    b.bettype,
        case 
            when b.bettype=9 then -9 
            when b.bettype = 10 or (b.bettype>30 and b.bettype<50) then isnull(o.leagueid,-1) 
            else isnull(m.leagueid,-1) 
        end as leagueid,	
	    b.currency,
	    b.statusid Status,
	    b.liveindicator,
        count(*) Betcount,
        count(distinct b.custid) MemberCount,
        sum(stake) Turnover,
        sum(winlost-actual_stake) winloss,
        sum(awinlost) winlossA,
	    sum(mwinlost) winlossM,
	    sum(swinlost) winlossS,
	    SUM(playercomm) commissionP,
	    SUM(comm) commissionA,
	    SUM(acomm) commissionM,
	    SUM(scomm) commissionS,
	    SUM((winlost-actual_stake)*virtualrate) WinLossVirtual,
	    SUM(scomm*virtualrate) CommissionSVirtual,
	    b.customercategory
    FROM
	    dbo.bettrans b with (nolock) 
	    left join bodb02.dbo.customer ag with (nolock) on b.recommend = ag.custid and ag.roleid = 2
	    left join bodb02.dbo.Site ibcsite with (nolock) on ag.site=ibcsite.site
	    left join dbo.view_site_list [site] with (nolock) on ibcsite.siteid=site.IbcSiteID	
	    left join dbo.match m with (nolock) on b.matchid = m.matchid
	    left join dbo.outright o with (nolock) on b.matchid = o.matchid
    WHERE isBA = 0
    GROUP BY
	    b.winlostdate,
	    isnull(site.SiteID,-1),
	    b.bettype,
        case 
            when b.bettype=9 then -9 
            when b.bettype = 10 or (b.bettype>30 and b.bettype<50) then isnull(o.leagueid,-1) 
            else isnull(m.leagueid,-1) 
        end,	
	    b.currency,
	    b.statusid,
	    b.liveindicator,
	    b.customercategory

/*
--update MTD table
exec dbo.GEN_RptKPI_MTD
    @date = @date, 
    @date2 = @date2,
    @stattype = 2,
    @isBA = 0
 */
 
GO
GRANT EXECUTE ON [dbo].[GEN_rptBetting_NegativeStake] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptBetting_NegativeStake] TO [VNTeam]