USE [bodb_LicenseeReport]
GO

/*
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GEN_RptKPI_MTD_Betting_product]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GEN_RptKPI_MTD_Betting_product]
GO
*/
/*
	GEN_RptKPI_MTD_Betting_3rdproduct
	@date='2012-10-30',
	@date2='2012-11-30'
*/
ALTER PROCEDURE [dbo].[GEN_RptKPI_MTD_Betting_3rdproduct]
    @date datetime, 
    @date2 datetime
AS
/*
Created: 20121024@Jim
Task: OWA - Add Number Game data to KPI report
DB: DBLIC.bodb_LicenseeReport
Original :[GEN_RptKPI_MTD_Betting]

Revisions:
    -20121109@Jim: add Virtual Sports data
	-20121226@Jim: add Live Casino data 
	-20140528@Jim: add Keno data
	-20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
Param's Explanation:
	
*/

CREATE TABLE #Betting
(
     rptDate datetime
    ,SiteID int
    ,CurrencyID int
	,Bettype 	int
    ,BetCount int
    ,Turnover float
    ,WLOfTicketsLoss float
    ,WLOfTicketsWon float
    ,SportRevenueTransaction float
    ,SportRevenueTicketsLoss float
    ,SportRevenueOthers float
    ,BetCountNoDraw int
    ,TurnoverNoDraw float
    ,BetCountLive int
    ,TurnoverLive float
)

DECLARE @Labels TABLE(LabelID int, TnxRate money, PRIMARY KEY(LabelID))
BEGIN

    INSERT INTO @Labels 
        SELECT LabelID, TnxRate FROM bodb_Licensee.dbo.view_kpi_labels (NOLOCK) WHERE ResellerID <> 3
    
    INSERT INTO #Betting
        SELECT 
             b.rptDate 
            ,b.SiteID 
			,b.CurrencyID
			,b.bettype
            ,sum(b.betcount) BetCount 
            ,sum(b.turnover) Turnover 
            ,sum(case when b.status in (113,115) then b.winloss else 0 end) WLOfTicketsLoss 
            ,sum(case when b.status in (112,114) then b.winloss else 0 end) WLOfTicketsWon 
            ,isnull(sum(b.betcount*TnxRate),0) SportRevenueTransaction 
            ,0 SportRevenueTicketsLoss 
            ,0 SportRevenueOthers 
            ,sum(case when b.status = 111 then 0 else b.betcount end) BetCountNoDraw 
            ,sum(case when b.status = 111 then 0 when b.status in (114,115) then (0.5*b.turnover) else b.turnover end) TurnoverNoDraw 
            ,sum(case when b.isLive = 1 then b.betcount else 0 end) BetCountLive 
            ,sum(case when b.isLive = 1 then b.turnover else 0 end) TurnoverLive 
        FROM dbo.rpt_Betting b (NOLOCK)
            INNER JOIN @Labels s ON b.SiteID = s.LabelID
        WHERE b.rptDate >= @date AND b.rptDate < @date2
            AND b.status NOT IN (-1,103)
            AND b.CurrencyID <> 20
            AND ((b.bettype BETWEEN 81 AND 120) 	  -- number game	
				OR (b.bettype BETWEEN 1201 AND 1299)  -- virtual sport
				OR (bettype BETWEEN 1101 AND 1199)    -- live casino
				OR (bettype BETWEEN 1501 AND 1599)    -- keno
				)
            AND isnull(b.customercategory,0) NOT IN (27,28)
        GROUP BY b.rptDate, b.SiteID,b.bettype, b.CurrencyID
	
	Update #Betting
	Set SportRevenueTicketsLoss=(WLOfTicketsLoss +WLOfTicketsWon)
	
    DELETE dbo.rptKPI_MTD_3rdProducts WHERE (rptDate >= @date AND rptDate < @date2) 
	AND ((bettype BETWEEN 81 AND 120)  -- number game	
		 OR (bettype BETWEEN 1201 AND 1299)  -- virtual sport
		 OR (bettype BETWEEN 1101 AND 1199)  -- live casino
		 OR (bettype BETWEEN 1501 AND 1599)) -- keno

	INSERT INTO dbo.rptKPI_MTD_3rdProducts
        SELECT 
				b.rptDate
				,b.SiteID
				,b.CurrencyID
				,cast(f.StatID as int) AS  StatID
				,b.bettype
				,f.MTD
        FROM #Betting b
            CROSS APPLY (
                SELECT 7, BetCount UNION ALL
                SELECT 9, Turnover UNION ALL
                SELECT 10, WLOfTicketsLoss UNION ALL
                SELECT 11, WLOfTicketsWon UNION ALL
                SELECT 14, SportRevenueTransaction UNION ALL
                SELECT 15, SportRevenueTicketsLoss UNION ALL
                SELECT 16, SportRevenueOthers UNION ALL
                SELECT 17, BetCountNoDraw UNION ALL
                SELECT 19, TurnoverNoDraw UNION ALL
                SELECT 22, BetCountLive UNION ALL
                SELECT 23, TurnoverLive 
            ) f(StatID,MTD)
          

END

DROP TABLE #Betting
GO
GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Betting_3rdproduct] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_RptKPI_MTD_Betting_3rdproduct] TO [vnteam] AS [dbo]