USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_rptBetting]
    @date datetime, 
    @date2 datetime = null
AS

/*
Created: 20110517@Elly
Task: Generate data into rpt_Betting 
DB: DBLIC.bodb_LicenseeReport

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
	20160129@Jim: fix bug #51781
	20160321@Victor: Support Colossus bet [Redmine: #52575]
	20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
	-20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]

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
		,[COTicketCount]
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
		,[BuyBackAmount]
		,[WinPrizeAmount]
		,[CashOutAmount]
		,[TicketPayout]
		,[oddsspread])
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
		COUNT(DISTINCT b.refno) COTicketCount,
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
		SUM(CASE 
				WHEN b.bettype IN (901, 911) THEN winlost 
				WHEN b.bettype = 18000 THEN ISNULL(CashInAmount,0)
				ELSE 0 
			END) BuyBackAmount,
		SUM(ISNULL(WinPrizeAmount,0)) WinPrizeAmount,
		SUM(ISNULL(CashOutAmount,0)) CashOutAmount, -- Cashout Value of Cashout Product
		SUM(ISNULL(TicketPayout, 0)) TicketPayout,
		SUM(ISNULL(oddsspread,0))    oddsspread
    FROM
	    dbo.bettrans b (NOLOCK) 
	    LEFT JOIN bodb02.dbo.customer ag (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
	    LEFT JOIN bodb02.dbo.Site ibcsite (NOLOCK) ON ag.site=ibcsite.site
	    LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	    LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
	    LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid
	    LEFT JOIN DBRPT.bodb02.dbo.VSRaceInfo RaceInfo WITH (NOLOCK) ON b.matchid = RaceInfo.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
    WHERE isBA=0
    GROUP BY
	    b.winlostdate,
	    ISNULL(site.SiteID,-1),
	    b.bettype,
        CASE 
            WHEN b.bettype = 9 THEN -9 
            WHEN b.bettype = 10 OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1) 
            WHEN b.bettype IN(1231,1232,1233,1237,1238) THEN RaceInfo.LeagueID
            ELSE ISNULL(m.leagueid,-1) 
        END,	
	    b.currency,
	    b.statusid,
	    b.liveindicator,
	    b.customercategory
 	 
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
GRANT EXECUTE ON [dbo].[GEN_rptBetting] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GEN_rptBetting] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptBetting] TO [vnteam] AS [dbo]