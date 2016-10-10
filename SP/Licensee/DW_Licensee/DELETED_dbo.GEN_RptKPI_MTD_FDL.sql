IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GEN_RptKPI_MTD_FDL]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GEN_RptKPI_MTD_FDL]
GO

CREATE PROCEDURE [dbo].[GEN_RptKPI_MTD_FDL]
    @date datetime, 
    @date2 datetime = -1,
    @stattype tinyint = 0,
    @isBA bit = 0,
	@debug bit = 0
AS
/*
Created: 20111121@Don
Task: Generate data into RptKPI_MTD from summary table
DB: DB052.bodb_Licensee

Revisions:
    +20120427@Jim: exclude data for BARM (customercategory=28)
	+20131104@Jim: move table rpt_betting to bodb_LicenseeReport DB
Param's Explanation:

*/

declare @sqlBettingExchangeDaily nvarchar(1000)
select @sqlBettingExchangeDaily =
	N'DECLARE @ExchangeDaily TABLE(ExchangeDate smalldatetime,ExchangeId int,EUR float,unique clustered (ExchangeDate,ExchangeId)) ' + char(13) 
select @sqlBettingExchangeDaily = @sqlBettingExchangeDaily + 
	N'INSERT INTO @ExchangeDaily(ExchangeDate,ExchangeId,EUR) ' +
	N'SELECT exchangedate,exchangeid,EUR FROM bodb02.dbo.exchangedaily WITH(NOLOCK) WHERE exchangedate >= ''' + convert(varchar(10),@date, 120) + '''AND exchangedate < ''' + convert(varchar(10),@date2, 120) + ''' ' + char(13) 



-- ****** rptKPI_Transfer ******
declare @sqlTransfer nvarchar(max)
if @stattype in(0,1)
begin
    --Insert transfer stats
    select @sqlTransfer = @sqlBettingExchangeDaily + char(13) + 'INSERT INTO dbo.rptKPI_MTD' + char(13) 

    select @sqlTransfer = @sqlTransfer + 
     'SELECT rptDate, SiteID, ' + convert(varchar(3),StatID) + ' StatID, ' + 
     case StatID 
	    when 1 then 'sum(FirstTransferInCount)'--1st Transfer In Count
	    when 2 then 'sum(FirstTransferInAmt*EUR)'-- 1st Transfer In Amount
	    when 3 then 'sum(TransferInCount)'-- Transfer In count
	    when 4 then 'sum(TransferOutCount)'-- Transfer Out Count
	    else NULL
     end + ' Value' + char(13) +
     'FROM dbo.rptKPI_Transfer b with (nolock)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     'WHERE	rptDate >= ''' + convert(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + convert(varchar(10),@date2, 120) + '''' + char(13) +
     'GROUP BY rptDate, SiteID' + char(13) +
     'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats with (nolock) where StatID between 1 and 4

    select @sqlTransfer = LEFT(@sqlTransfer, LEN(@sqlTransfer)-10)
end


-- ****** rptKPI_Betting ******
declare @sqlBetting nvarchar(max), @sqlBetting2 nvarchar(max), @sqlBetting3 nvarchar(max)
if @stattype in(0,2)
begin
    --Insert Betting stats
    
    -- For betting statID between 7 and 11
    select @sqlBetting = @sqlBettingExchangeDaily + char(13) /*+ @sqlBettingLeague + char(13)*/ + 'INSERT INTO @bettingdestination' + char(13) 

    select @sqlBetting = @sqlBetting + 
     'SELECT rptDate, b.SiteID, ' + convert(varchar(3),StatID) + ' StatID, ' + 
     case StatID 
	    when  7 then 'sum(BetCount)'--BetCount
	    when  9 then 'sum(turnover*EUR)'-- Turnover
	    when 10 then 'sum(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
	    when 11 then 'sum(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
	    when 14 then 'isnull(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
	    when 15 then 'isnull(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
	    when 16 then 'isnull(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
	    when  17 then 'sum(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
	    when  19 then 'sum((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
	    when 22 then 'sum(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
	    when 23 then 'sum(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
	    else NULL
     end + ' Value' + char(13) +
     'FROM @bettingsource b with (nolock)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     --'  LEFT JOIN dbo.LicenseeReseller s with (nolock) ON b.SiteID = s.LicenseeID' + char(13) +     
     '  LEFT JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (nolock) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID = s.LicenseeID' + char(13) +     
     'WHERE	rptDate >= ''' + convert(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + convert(varchar(10),@date2, 120) + '''' + char(13) +
     ' and b.status not in(-1,103)' + char(13) +
     ' and b.currencyID <> 20' + char(13) +
     ' and b.bettype not between 31 and 120' + char(13) +
     case when @isBA = convert(bit,0) then ' and isnull(b.customercategory,-1) NOT IN (27,28)' else '' end + char(13) +
     ' and b.siteid in (1029,1025,1035,1013,1001,1016)' + char(13) +
     'GROUP BY rptDate, b.SiteID, TnxRate' + char(13) +
     'UNION ALL' + char(13)
    FROM tblKPI_Stats with (nolock) where (StatID between 7 and 11) and (StatID not in (8,12,13,18,20,21))

    select @sqlBetting = LEFT(@sqlBetting, LEN(@sqlBetting)-10) + char(13) /*+ @sqlBettingRemoveLeague*/
    
    
    -- For betting statID between 12 and 16
    select @sqlBetting2 = @sqlBettingExchangeDaily + char(13) /*+ @sqlBettingLeague + char(13)*/ + 'INSERT INTO @bettingdestination' + char(13) 

    select @sqlBetting2 = @sqlBetting2 + 
     'SELECT rptDate, b.SiteID, ' + convert(varchar(3),StatID) + ' StatID, ' + 
     case StatID 
	    when  7 then 'sum(BetCount)'--BetCount
	    when  9 then 'sum(turnover*EUR)'-- Turnover
	    when 10 then 'sum(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
	    when 11 then 'sum(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
	    when 14 then 'isnull(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
	    when 15 then 'isnull(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
	    when 16 then 'isnull(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
	    when  17 then 'sum(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
	    when  19 then 'sum((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
	    when 22 then 'sum(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
	    when 23 then 'sum(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
	    else NULL
     end + ' Value' + char(13) +
     'FROM @bettingsource b with (nolock)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     --'  LEFT JOIN dbo.LicenseeReseller s with (nolock) ON b.SiteID = s.LicenseeID' + char(13) +     
     '  LEFT JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (nolock) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID = s.LicenseeID' + char(13) +
     'WHERE	rptDate >= ''' + convert(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + convert(varchar(10),@date2, 120) + '''' + char(13) +
     ' and b.status not in(-1,103)' + char(13) +
     ' and b.currencyID <> 20' + char(13) +
     ' and b.bettype not between 31 and 120' + char(13) +
     case when @isBA = convert(bit,0) then ' and isnull(b.customercategory,-1) NOT IN  (27,28)' else '' end + char(13) +
     ' and b.siteid in (1029,1025,1035,1013,1001,1016)' + char(13) +
     'GROUP BY rptDate, b.SiteID, TnxRate' + char(13) +
     'UNION ALL' + char(13)
    FROM tblKPI_Stats with (nolock) where StatID between 12 and 16 and StatID not in (8,12,13,18,20,21)
    
    select @sqlBetting2 = LEFT(@sqlBetting2, LEN(@sqlBetting2)-10) /*+ char(13) + @sqlBettingRemoveLeague*/


	-- For betting statID between 17 and 23
    select @sqlBetting3 = @sqlBettingExchangeDaily + char(13) /*+ @sqlBettingLeague + char(13)*/ + 'INSERT INTO @bettingdestination' + char(13) 

    select @sqlBetting3 = @sqlBetting3 + 
     'SELECT rptDate, b.SiteID, ' + convert(varchar(3),StatID) + ' StatID, ' + 
     case StatID 
	    when  7 then 'sum(BetCount)'--BetCount
	    when  9 then 'sum(turnover*EUR)'-- Turnover
	    when 10 then 'sum(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
	    when 11 then 'sum(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
	    when 14 then 'isnull(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
	    when 15 then 'isnull(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
	    when 16 then 'isnull(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
	    when  17 then 'sum(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
	    when  19 then 'sum((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
	    when 22 then 'sum(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
	    when 23 then 'sum(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
	    else NULL
     end + ' Value' + char(13) +
     'FROM @bettingsource b with (nolock)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     --'  LEFT JOIN dbo.LicenseeReseller s with (nolock) ON b.SiteID = s.LicenseeID' + char(13) +     
     '  LEFT JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (nolock) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID = s.LicenseeID' + char(13) +
     'WHERE	rptDate >= ''' + convert(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + convert(varchar(10),@date2, 120) + '''' + char(13) +
     ' and b.status not in(-1,103)' + char(13) +
     ' and b.currencyID <> 20' + char(13) +
     ' and b.bettype not between 31 and 120' + char(13) +
     case when @isBA = convert(bit,0) then ' and isnull(b.customercategory,-1) NOT IN  (27,28)' else '' end + char(13) +
     ' and b.siteid in (1029,1025,1035,1013,1001,1016)' + char(13) +
     'GROUP BY rptDate, b.SiteID, TnxRate' + char(13) +
     'UNION ALL' + char(13)
    FROM tblKPI_Stats with (nolock) where (StatID between 17 and 23) and (StatID not in (8,12,13,18,20,21))

    select @sqlBetting3 = LEFT(@sqlBetting3, LEN(@sqlBetting3)-10) /*+ char(13) + @sqlBettingRemoveLeague*/
end


-- ****** rptKPI_Account ******
declare @sqlAccount nvarchar(max)
if @stattype in(0,3)
begin
    --Insert Account stats

    select @sqlAccount = 'INSERT INTO @accountdestination' + char(13) 

    select @sqlAccount = @sqlAccount + 
     'SELECT rptDate, SiteID, ' + convert(varchar(3),StatID) + ' StatID, ' + 
     case StatID 
	    when  5 then 'sum(UniqueBettorCount)/24'--Average Bettors during days
	    when  6 then 'sum(PeakBettorCount)/24'-- Peak concurrent bettors
	    else NULL
     end + ' Value' + char(13) +
     'FROM @accountsource b with (nolock)' + char(13) +
     'WHERE	rptDate >= ''' + convert(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + convert(varchar(10),@date2, 120) + '''' + char(13) +
     'GROUP BY rptDate, SiteID' + char(13) +
     'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats with (nolock) where StatID IN(5,6)

    select @sqlAccount = LEFT(@sqlAccount, LEN(@sqlAccount)-10)
end


if @stattype in(0,1) 
begin
    PRINT char(13) + '--Insert Transfer Stats:' + char(13)
	if (@debug = 1) PRINT @sqlTransfer    
    DELETE FROM dbo.RptKPI_MTD WHERE rptDate >= @date and rptdate < @date2 and StatID between 1 and 4
    exec sp_executesql @sqlTransfer
end
    
if @stattype in(0,2) 
begin
    PRINT char(13) + '--Insert Betting Stats:' + char(13)
    
    -- Gen
    PRINT char(13) + '--For Betting Stats (7-11):' + char(13)
    if (@isBA = convert(bit,1))
    begin
        DELETE FROM RptKPI_MTD_BA WHERE rptDate >= @date and rptdate < @date2 and StatID between 7 and 23 and SiteID in (1029,1025,1035,1013,1001,1016)
        
        select @sqlBetting = REPLACE(@sqlBetting,'@bettingdestination','dbo.rptKPI_MTD_BA')
        select @sqlBetting = REPLACE(@sqlBetting,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting_BA')
        select @sqlBetting = REPLACE(@sqlBetting,'@ResellerCondition','ResellerID = 3') -- BA Reseller:3
    end
    else
    begin
        DELETE FROM RptKPI_MTD WHERE rptDate >= @date and rptdate < @date2 and StatID between 7 and 23 and SiteID in (1029,1025,1035,1013,1001,1016)
        
        select @sqlBetting = REPLACE(@sqlBetting,'@bettingdestination','dbo.rptKPI_MTD')
        select @sqlBetting = REPLACE(@sqlBetting,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
        select @sqlBetting = REPLACE(@sqlBetting,'@ResellerCondition','ResellerID IN (1,2,4,5)') -- Resellers: GWI,OneNet,FDL,Cozni
    end
    if (@debug = 1) PRINT @sqlBetting
    exec sp_executesql @sqlBetting
    
    -- Gen
    PRINT char(13) + '--For Betting Stats (12-16):' + char(13)
    if (@isBA = convert(bit,1))
    begin
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingdestination','dbo.rptKPI_MTD_BA')
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting_BA')
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@ResellerCondition','ResellerID = 3') -- BA Reseller:3
    end
    else
    begin
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingdestination','dbo.rptKPI_MTD')
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
        select @sqlBetting2 = REPLACE(@sqlBetting2,'@ResellerCondition','ResellerID IN (1,2,4,5)') -- Resellers: GWI,OneNet,FDL,Cozni
    end
    if (@debug = 1) PRINT @sqlBetting2
    exec sp_executesql @sqlBetting2
    
    -- Gen
    PRINT char(13) + '--For Betting Stats (17-23):' + char(13)
    if (@isBA = convert(bit,1))
    begin
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingdestination','dbo.rptKPI_MTD_BA')
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting_BA')
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@ResellerCondition','ResellerID = 3') -- BA Reseller:3
    end
    else
    begin
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingdestination','dbo.rptKPI_MTD')
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
        select @sqlBetting3 = REPLACE(@sqlBetting3,'@ResellerCondition','ResellerID IN (1,2,4,5)') -- Resellers: GWI,OneNet,FDL,Cozni
    end
    if (@debug = 1) PRINT @sqlBetting3
    exec sp_executesql @sqlBetting3
end

if @stattype in(0,3)
begin
    PRINT char(13) + '--Insert Account Stats:' + char(13)
    
    if (@isBA = convert(bit,1))
    begin
        DELETE FROM dbo.RptKPI_MTD_BA WHERE rptDate >= @date and rptdate < @date2 and StatID IN(5,6)
	
	    select @sqlAccount = REPLACE(@sqlAccount,'@accountdestination','dbo.rptKPI_MTD_BA')
	    select @sqlAccount = REPLACE(@sqlAccount,'@accountsource','dbo.rptKPI_Account_BA')
    end
    else
    begin
        DELETE FROM dbo.RptKPI_MTD WHERE rptDate >= @date and rptdate < @date2 and StatID IN(5,6)
        
        select @sqlAccount = REPLACE(@sqlAccount,'@accountdestination','dbo.rptKPI_MTD')
	    select @sqlAccount = REPLACE(@sqlAccount,'@accountsource','dbo.rptKPI_Account')
    end
    
    if (@debug = 1) PRINT @sqlAccount
    exec sp_executesql @sqlAccount
end

GO
GRANT VIEW DEFINITION ON [dbo].[GEN_RptKPI_MTD_FDL] TO [VNTeam] 