USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GEN_RptKPI_MTD_Betting]    Script Date: 01/28/2015 01:42:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.GEN_RptKPI_MTD_Betting    Script Date: 8/22/2012 11:20:22 AM ******/

CREATE PROCEDURE [dbo].[GEN_RptKPI_MTD_Betting]
    @date datetime, 
    @date2 datetime,
    @isBA bit = 0
AS
/*
Created: 20120810@Don
Task: Generate data into GEN_RptKPI_MTD from rpt_Betting
DB: DB052.bodb_Licensee

Revisions:
    
Param's Explanation:

*/

CREATE TABLE #Betting
(
     rptDate datetime
    ,SiteID int
    ,CurrencyID int
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

IF @isBA = 0
BEGIN

    INSERT INTO @Labels 
        SELECT LabelID, TnxRate FROM dbo.view_kpi_labels (NOLOCK) WHERE ResellerID <> 3
    
    INSERT INTO #Betting
        SELECT 
             b.rptDate 
            ,b.SiteID 
            ,b.CurrencyID
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
            AND ( b.bettype < 31 OR (b.bettype >= 121 AND b.bettype < 1000) )
            AND isnull(b.customercategory,0) NOT IN (27,28)
        GROUP BY b.rptDate, b.SiteID, b.CurrencyID

    DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID BETWEEN 7 AND 23

    INSERT INTO dbo.rptKPI_MTD_Cross
        SELECT b.rptDate, b.SiteID, b.CurrencyID, cast(f.StatID as int) StatID, f.MTD
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
ELSE
BEGIN

    INSERT INTO @Labels 
        SELECT LabelID, TnxRate FROM dbo.view_kpi_labels (NOLOCK) WHERE ResellerID = 3
        
    INSERT INTO #Betting
        SELECT 
            b.rptDate 
            ,b.SiteID 
            ,b.CurrencyID
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
        FROM dbo.rpt_Betting_BA b (NOLOCK)
            INNER JOIN @Labels s ON b.SiteID = s.LabelID
        WHERE b.rptDate >= @date AND b.rptDate < @date2
            AND b.status NOT IN (-1,103)
            AND b.CurrencyID <> 20
        GROUP BY b.rptDate, b.SiteID, b.CurrencyID
        
    DELETE dbo.rptKPI_MTD_BA_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID BETWEEN 7 AND 23
            
    INSERT INTO dbo.rptKPI_MTD_BA_Cross
        SELECT b.rptDate, b.SiteID, b.CurrencyID, cast(f.StatID as int) StatID, f.MTD
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

GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Betting] TO [bodbLicenseeNet] AS [dbo]
GO


