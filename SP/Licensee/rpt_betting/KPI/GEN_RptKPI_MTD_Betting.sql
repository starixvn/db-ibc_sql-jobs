USE [bodb_licensee]
GO
ALTER PROCEDURE [dbo].[GEN_RptKPI_MTD_Betting]
    @date datetime, 
    @date2 datetime,
    @isBA bit = 0
AS
/*
Created: 20120810@Don
Task: Generate data into GEN_RptKPI_MTD from rpt_Betting
DB: DB052.bodb_Licensee

Revisions:
-20160116@Francis: Support BetTrade
-20160810@Francis: BetTrade commercial terms changed [Redmine: #62111]
    
Param's Explanation:

*/
BEGIN
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

	CREATE TABLE #BettingBetTrade
	(
		 rptDate datetime
		,SiteID int
		,CurrencyID int
		,BoughtTicketCount int
		,Actual_Stake money
		,BuyBackAmount money
		,ProfitOnBuyBack money
		,BoughtTicketWL money
		,CommShare money
		,ProfitSharing money
	)

	DECLARE @Labels TABLE(LabelID int, TnxRate money, PRIMARY KEY(LabelID))

	IF @isBA = 0
	BEGIN

		INSERT INTO @Labels 
			SELECT LabelID, TnxRate FROM dbo.view_kpi_labels (NOLOCK) WHERE ResellerID <> 3
	    
		INSERT INTO #Betting (rptDate, SiteID, CurrencyID, BetCount, Turnover, WLOfTicketsLoss, WLOfTicketsWon, SportRevenueTransaction, SportRevenueTicketsLoss
							  ,SportRevenueOthers, BetCountNoDraw, TurnoverNoDraw, BetCountLive, TurnoverLive)
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
				AND (b.bettype < 31 OR (b.bettype >= 121 AND b.bettype < 1000 AND b.Bettype NOT IN (901,902,903,904)))
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

	--For BetTrade
	INSERT INTO #BettingBetTrade (rptDate, SiteID, CurrencyID, BoughtTicketCount, Actual_Stake, BuyBackAmount, ProfitOnBuyBack, BoughtTicketWL, CommShare, ProfitSharing)
        SELECT 
             b.rptDate 
            ,b.SiteID 
            ,b.CurrencyID
            ,sum(case when b.Bettype = 901 then b.BetCount else 0 end) as BoughtTicketCount
            ,sum(case when b.Bettype = 901 then b.BuyBackAmount - b.WinLoss else 0 end) as Actual_Stake
            ,sum(case when b.Bettype = 901 then b.BuyBackAmount else 0 end) as BuyBackAmount
            ,sum(case when b.Bettype = 901 then -b.WinLoss else 0 end) as ProfitOnBuyBack
            ,sum(case when b.Bettype NOT IN (901,902,903,904) then b.WinLoss else 0 end) as BoughtTicketWL --only count BetTrade original tickets
            ,sum(case when b.Bettype = 903 then -(b.WinLoss + b.WinLossA) else 0 end) as CommShare
            ,sum(case when b.Bettype IN (903,904) then -(b.WinLoss + b.WinLossA) else 0 end) as ProfitSharing
        FROM dbo.rpt_Betting b (NOLOCK)
        WHERE b.rptDate >= @date AND b.rptDate < @date2
            AND b.status NOT IN (-1,103)
            AND b.CurrencyID <> 20
            AND b.CustomerCategory IN (1001,1002) --All BetTrade tickets with original tickets included
        GROUP BY b.rptDate, b.SiteID, b.CurrencyID     
       
   MERGE #BettingBetTrade AS TARGET
   USING     
			(SELECT 
				 b.rptDate 
				,b.SiteID 
				,b.CurrencyID
				,sum(case when b.Bettype NOT IN (901,902,903,904) then b.WinLoss else 0 end) as BoughtTicketWL --only count BetTrade BA original tickets
			FROM dbo.rpt_Betting_BA b (NOLOCK)
			WHERE b.rptDate >= @date AND b.rptDate < @date2
				AND b.status NOT IN (-1,103)
				AND b.CurrencyID <> 20
				AND b.CustomerCategory IN (1001,1002) --All BetTrade tickets with original tickets included
			GROUP BY b.rptDate, b.SiteID, b.CurrencyID)
	AS SOURCE (rptDate, SiteID, CurrencyID, BoughtTicketWL) ON (TARGET.rptDate = SOURCE.rptDate AND TARGET.SiteID = SOURCE.SiteID AND TARGET.CurrencyID = SOURCE.CurrencyID)
	WHEN MATCHED THEN
		UPDATE SET TARGET.BoughtTicketWL = TARGET.BoughtTicketWL + SOURCE.BoughtTicketWL;
    
    DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID BETWEEN 30 AND 40
    
    INSERT INTO dbo.rptKPI_MTD_Cross
			SELECT b.rptDate, b.SiteID, b.CurrencyID, cast(f.StatID as int) StatID, f.MTD
			FROM #BettingBetTrade b
				CROSS APPLY (
					SELECT 30, BoughtTicketCount UNION ALL
					SELECT 35, BoughtTicketCount UNION ALL
					SELECT 31, Actual_Stake UNION ALL
					SELECT 32, BuyBackAmount UNION ALL
					SELECT 33, CommShare UNION ALL
					SELECT 38, CommShare UNION ALL
					SELECT 36, ProfitOnBuyBack UNION ALL
					SELECT 37, BoughtTicketWL UNION ALL
					SELECT 39, ProfitSharing
				) f(StatID,MTD)
                
	DROP TABLE #Betting
	DROP TABLE #BettingBetTrade
END

GO
GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Betting] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_RptKPI_MTD_Betting] TO [vnteam] AS [dbo]