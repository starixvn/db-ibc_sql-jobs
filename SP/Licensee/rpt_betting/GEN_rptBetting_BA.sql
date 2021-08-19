/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[GEN_rptBetting_BA]
    @date datetime, 
    @date2 datetime = null
AS
/*
Created: 20110517@Daniel
Task: Generate data into rpt_Betting 
DB: DBLIC.bodb_LicenseeReport

Revisions:
	20110726@Daniel: Process data for BA
	20150623@Patrick: Support BetTrade
	20150917@Francis: Cast LiveIndicator to 0 if it is NULL
	20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
	20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
	20171019@Harper: LA - Shutdown KPI Report [RedmineID: #83983]
	20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768] 
	20190508@Parsons: Implement BetBuilder [Redmine: #108995]
	20210816@Sophia: add DBBAL [Redmine: #154300]

Param's Explanation:

EXEC GEN_rptBetting_BA '2018-01-01', '2018-01-28'

*/
IF @date2 IS NULL SET @date2 = @date
SET @date2 = DATEADD(day,1,@date2)

DELETE FROM dbo.rpt_Betting_BA
WHERE rptDate>=@date AND rptDate<@date2

INSERT INTO dbo.rpt_Betting_BA
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
		,[customercategory]
		,[BuyBackAmount]
		,[TicketType]
		,[ExtraAmount]
		)
    SELECT  
	    b.winlostdate,
        ISNULL(site.SiteID,-1) siteid,
	    b.bettype,
        CASE 
            WHEN b.bettype = 9 THEN -9 
			WHEN b.bettype = 2799 THEN -2799
			WHEN b.bettype = 10 OR (b.bettype<>38 AND b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)
            ELSE ISNULL(m.leagueid,-1) 
        END AS leagueid,	
	    b.currency,
	    ISNULL(sta.statusid,-1) [Status],
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
		SUM(CASE WHEN b.bettype IN (901) THEN winlost ELSE 0 END),
		b.TicketType,
		SUM(CASE WHEN b.bettype = 18000 THEN CONVERT(MONEY, ISNULL(b.ExtraInfo, 0)) ELSE 0 END) -- Extra Amount For CB Free Play Ticket
    FROM
	    dbo.bettrans b (NOLOCK) 
	    LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
	    LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
	    LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID	
	    LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
	    LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
	    LEFT JOIN bodb_Licensee.dbo.view_status_list sta (NOLOCK) ON b.Status = sta.StatusName
    WHERE isBA=1
    GROUP BY
	    b.winlostdate,
	    ISNULL(site.SiteID,-1),
	    b.bettype,
        CASE 
            WHEN b.bettype = 9 THEN -9 
			WHEN b.bettype = 2799 THEN -2799
			WHEN b.bettype = 10 OR (b.bettype<>38 AND b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)
            ELSE ISNULL(m.leagueid,-1) 
        END,	
	    b.currency,
	    ISNULL(sta.statusid,-1),
	    b.liveindicator,
	    b.customercategory,
		b.TicketType
		
GO