ALTER PROCEDURE [dbo].[DELETED_GEN_rptLicMemberBetting]
    @date datetime, 
    @date2 datetime = -1
AS
/*
Created: 20111026@Don
Task: Generate data into rpt_LicMemberBetting 
DB: DB052.bodb_Licensee

Revisions:

Param's Explanation:

*/
if @date2 = -1 set @date2 = @date
set @date2 = DATEADD(day,1,@date2)

DELETE FROM dbo.rpt_LicMemberBetting
WHERE rptDate >= @date and rptdate < @date2

INSERT INTO dbo.rpt_LicMemberBetting
SELECT  
	b.winlostdate,
	b.custid,
    isnull(site.SiteID,-1) siteid,
	b.bettype,
    CASE
        WHEN bettype NOT BETWEEN 31 AND 120 THEN CASE WHEN m.sporttype IS NOT NULL THEN m.sporttype WHEN o.sporttype IS NOT NULL THEN o.sporttype ELSE 0 END
		WHEN bettype IN (71,72) THEN 251
		WHEN bettype = 73 THEN 252 --Bingo 
		WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
		WHEN bettype BETWEEN 51 AND 69 THEN 201
		WHEN bettype IN (31,32,33) THEN 151
		ELSE 0 
    END sportid,
	b.currency,
	b.statusid Status,
	b.liveindicator,
    count(*) Betcount,
    sum(stake) Turnover,
    sum(winlost-actual_stake) winloss,
    sum(awinlost) winlossA,
	SUM(comm) commissionA,
	SUM((winlost-actual_stake)*virtualrate) WinLossVirtual,
	SUM(scomm*virtualrate) CommissionVirtual
FROM
	dbo.bettrans b with (nolock) 
	left join bodb02.dbo.customer ag with (nolock) on b.recommend = ag.custid and ag.roleid = 2
	left join bodb02.dbo.Site ibcsite with (nolock) on ag.site=ibcsite.site
	left join dbo.view_site_list [site] with (nolock) on ibcsite.siteid=site.IbcSiteID	
	left join dbo.match m with (nolock) on b.matchid = m.matchid
	left join dbo.outright o with (nolock) on b.matchid = o.matchid
WHERE
	b.winlostdate >= @date
	and b.winlostdate < @date2
	and isBA = 0
	and b.srecommend in (select custid from bodb02.dbo.f_DepSuper_1('all'))
GROUP BY
	b.winlostdate,
	b.custid,
	isnull(site.SiteID,-1),
	b.bettype,
    CASE
        WHEN bettype NOT BETWEEN 31 AND 120 THEN CASE WHEN m.sporttype IS NOT NULL THEN m.sporttype WHEN o.sporttype IS NOT NULL THEN o.sporttype ELSE 0 END
		WHEN bettype IN (71,72) THEN 251
		WHEN bettype = 73 THEN 252 --Bingo 
		WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
		WHEN bettype BETWEEN 51 AND 69 THEN 201
		WHEN bettype IN (31,32,33) THEN 151
		ELSE 0 
    END,
	b.currency,
	b.statusid,
	b.liveindicator

 
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptLicMemberBetting] TO [VNTeam]