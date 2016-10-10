IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GEN_RptKPI_MTD_CreditSites]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GEN_RptKPI_MTD_CreditSites]
GO

CREATE PROCEDURE [dbo].[GEN_RptKPI_MTD_CreditSites]
    @date datetime, 
    @date2 datetime = -1,
    @stattype tinyint = 0,
    @isBA bit = 0,
	@debug bit = 0
AS
/*
Created: 20111206@Don
Task: Generate data into GEN_RptKPI_MTD from summary tables (credit sites)
DB: DB052.bodb_Licensee

Revisions:
    -20120427@Jim: exclude data for  BARM agent (customercategory=28)
	-20131104@Jim: move table rpt_betting to bodb_LicenseeReport DB	
Param's Explanation:

*/

DECLARE @sqlBettingExchangeDaily nvarchar(1000)
SELECT @sqlBettingExchangeDaily =
	N'DECLARE @ExchangeDaily TABLE(ExchangeDate smalldatetime,ExchangeId int,EUR float,unique clustered (ExchangeDate,ExchangeId)) ' + char(13) 
SELECT @sqlBettingExchangeDaily = @sqlBettingExchangeDaily + 
	N'INSERT INTO @ExchangeDaily(ExchangeDate,ExchangeId,EUR) ' +
	N'SELECT exchangedate,exchangeid,EUR FROM bodb02.dbo.exchangedaily WITH(NOLOCK) WHERE exchangedate >= ''' + convert(varchar(10),@date, 120) + '''AND exchangedate < ''' + convert(varchar(10),@date2, 120) + ''' ' + char(13) 
	


-- ****** rptKPI_Transfer ******
DECLARE @sqlTransfer nvarchar(max)
IF @stattype IN (0,1)
BEGIN
    --Insert transfer stats
    SELECT @sqlTransfer = @sqlBettingExchangeDaily + char(13) + 'INSERT INTO dbo.rptKPI_MTD' + char(13) 

    SELECT @sqlTransfer = @sqlTransfer + 
     'SELECT rptDate, SiteID, ' + CONVERT(varchar(3),StatID) + ' StatID, ' + 
     CASE StatID 
	    WHEN 1 THEN 'sum(FirstTransferInCount)'--1st Transfer In Count
	    WHEN 2 THEN 'sum(FirstTransferInAmt*EUR)'-- 1st Transfer In Amount
	    WHEN 3 THEN 'sum(TransferInCount)'-- Transfer In count
	    WHEN 4 THEN 'sum(TransferOutCount)'-- Transfer Out Count
	    ELSE null
     END + ' Value' + char(13) +
     'FROM dbo.rptKPI_Transfer b with (nolock)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     'WHERE	rptDate >= ''' + CONVERT(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + CONVERT(varchar(10),@date2, 120) + '''' + char(13) +
     'GROUP BY rptDate, SiteID' + char(13) +
     'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats (NOLOCK) 
    WHERE StatID BETWEEN 1 AND 4

    SELECT @sqlTransfer = LEFT(@sqlTransfer, LEN(@sqlTransfer)-10)
END


-- ****** rptKPI_Betting ******
DECLARE @sqlBetting nvarchar(max), @sqlBetting2 nvarchar(max), @sqlBetting3 nvarchar(max)
IF @stattype IN (0,2)
BEGIN
    --Insert Betting stats
    
    -- For betting statID between 7 and 11
    SELECT @sqlBetting = @sqlBettingExchangeDaily + char(13) + 'INSERT INTO @bettingdestination' + char(13) 

    SELECT @sqlBetting = @sqlBetting + 
     'SELECT b.rptDate,b.SiteID,' + CONVERT(varchar(3),StatID) + ' StatID,' + 
     CASE StatID 
	    WHEN  7 THEN 'SUM(BetCount)'--BetCount
	    WHEN  9 THEN 'SUM(turnover*EUR)'-- Turnover
	    WHEN 10 THEN 'SUM(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
	    WHEN 11 THEN 'SUM(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
	    WHEN 14 THEN 'ISNULL(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
	    WHEN 15 THEN 'ISNULL(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
	    WHEN 16 THEN 'ISNULL(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
	    WHEN 17 THEN 'SUM(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
	    WHEN 19 THEN 'SUM((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
	    WHEN 22 THEN 'SUM(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
	    WHEN 23 THEN 'SUM(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
	    ELSE null
     END + ' Value' + char(13) +
     'FROM @bettingsource b (NOLOCK)' + char(13) +
     '  LEFT JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
     '  INNER JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (nolock) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID=s.LicenseeID' + char(13) +     
     'WHERE	b.rptDate>= ''' + CONVERT(varchar(10),@date, 120) + '''' +
     ' AND b.rptDate< ''' + CONVERT(varchar(10),@date2, 120) + '''' + char(13) +
     ' AND b.status NOT IN (-1,103)' + char(13) +
     ' AND b.currencyID<>20' + char(13) +
     ' AND (b.bettype<31 OR (b.bettype>=121 AND b.bettype<1000))' + char(13) +
     CASE WHEN @isBA = CONVERT(bit,0) THEN ' AND b.customercategory NOT IN (27,28)' ELSE '' END + char(13) +
     'GROUP BY b.rptDate,b.SiteID,s.TnxRate' + char(13) +
     'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats (NOLOCK) 
    WHERE (StatID BETWEEN 7 AND 11) AND (StatID NOT IN (8,12,13,18,20,21))

    select @sqlBetting = LEFT(@sqlBetting, LEN(@sqlBetting)-10) + char(13) 
    
    
    -- For betting statID between 12 and 16
    SELECT @sqlBetting2 = @sqlBettingExchangeDaily + char(13) + 'INSERT INTO @bettingdestination' + char(13) 

    SELECT @sqlBetting2 = @sqlBetting2 + 
        'SELECT b.rptDate,b.SiteID,' + CONVERT(varchar(3),StatID) + ' StatID,' + 
            CASE StatID 
            WHEN 7 THEN 'SUM(BetCount)'--BetCount
            WHEN 9 THEN 'SUM(turnover*EUR)'-- Turnover
            WHEN 10 THEN 'SUM(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
            WHEN 11 THEN 'SUM(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
            WHEN 14 THEN 'ISNULL(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
            WHEN 15 THEN 'ISNULL(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
            WHEN 16 THEN 'ISNULL(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
            WHEN 17 THEN 'SUM(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
            WHEN 19 THEN 'SUM((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
            WHEN 22 THEN 'SUM(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
            WHEN 23 THEN 'SUM(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
            ELSE null
            END + ' Value' + char(13) +
        'FROM @bettingsource b (NOLOCK)' + char(13) +
            '  INNER JOIN @ExchangeDaily e ON b.currencyID = e.exchangeid AND b.rptdate = e.exchangedate' + char(13) +
            '  INNER JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (NOLOCK) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID=s.LicenseeID' + char(13) +
        'WHERE	b.rptDate>= ''' + CONVERT(varchar(10),@date, 120) + '''' +
            ' AND b.rptDate< ''' + CONVERT(varchar(10),@date2, 120) + '''' + char(13) +
            ' AND b.status NOT IN (-1,103)' + char(13) +
            ' AND b.currencyID<>20' + char(13) +
            ' AND (b.bettype<31 OR (b.bettype>=121 AND b.bettype<1000))' + char(13) +
            CASE WHEN @isBA = CONVERT(bit,0) THEN ' AND b.customercategory NOT IN (27,28)' ELSE '' END + char(13) +
        'GROUP BY b.rptDate,b.SiteID,s.TnxRate' + char(13) +
        'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats (NOLOCK) 
    WHERE (StatID BETWEEN 12 AND 16) AND (StatID NOT IN (8,12,13,18,20,21))
    
    SELECT @sqlBetting2 = LEFT(@sqlBetting2, LEN(@sqlBetting2)-10)


	-- For betting statID between 17 and 23
    SELECT @sqlBetting3 = @sqlBettingExchangeDaily + char(13) + 'INSERT INTO @bettingdestination' + char(13) 

    SELECT @sqlBetting3 = @sqlBetting3 + 
        'SELECT b.rptDate,b.SiteID,' + CONVERT(varchar(3),StatID) + ' StatID,' + 
            CASE StatID 
            WHEN 7 THEN 'SUM(BetCount)'--BetCount
            WHEN 9 THEN 'SUM(turnover*EUR)'-- Turnover
            WHEN 10 THEN 'SUM(case when status in (113,115) then WinLoss*EUR else 0 end)'-- Winloss of player bets that loss
            WHEN 11 THEN 'SUM(case when status in (112,114) then WinLoss*EUR else 0 end)'-- Winloss of player bets that won
            WHEN 14 THEN 'ISNULL(sum(BetCount)*TnxRate,0)'-- Sport revenue - transaction
            WHEN 15 THEN 'ISNULL(sum(case when status in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Player losses
            WHEN 16 THEN 'ISNULL(sum(case when status not in (113,115) then Betcount*TnxRate else 0 end),0)'-- Sport revenue - Others
            WHEN 17 THEN 'SUM(case when status = 111 then 0 else BetCount end)'-- BetCount (no draw)
            WHEN 19 THEN 'SUM((case when status = 111 then 0 when status in (114,115) then (0.5*turnover)*EUR else turnover*EUR end))'-- Turnover (no draw)
            WHEN 22 THEN 'SUM(case when IsLive = 1 then BetCount else 0 end)'-- BetCount Live
            WHEN 23 THEN 'SUM(case when IsLive = 1 then turnover*EUR else 0 end)'-- Turnover Live
            ELSE null
            END + ' Value' + char(13) +
        'FROM @bettingsource b with (NOLOCK)' + char(13) +
            '  INNER JOIN @ExchangeDaily e ON b.currencyID=e.exchangeid AND b.rptDate=e.exchangedate' + char(13) +
            '  INNER JOIN (SELECT LicenseeID,TnxRate FROM dbo.LicenseeReseller (NOLOCK) WHERE LicenseeID<>13 AND @ResellerCondition) s ON b.SiteID=s.LicenseeID' + char(13) +
        'WHERE	b.rptDate>= ''' + CONVERT(varchar(10),@date, 120) + '''' +
            ' AND b.rptDate< ''' + CONVERT(varchar(10),@date2, 120) + '''' + char(13) +
            ' AND b.status NOT IN (-1,103)' + char(13) +
            ' AND b.currencyID<>20' + char(13) +
            ' AND (b.bettype<31 OR (b.bettype>=121 AND b.bettype<1000))' + char(13) +
            CASE WHEN @isBA = CONVERT(bit,0) THEN ' AND b.customercategory NOT IN (27,28)' ELSE '' END + char(13) +
        'GROUP BY b.rptDate,b.SiteID,s.TnxRate' + char(13) +
        'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats (NOLOCK) 
    WHERE (StatID BETWEEN 17 AND 23) AND (StatID NOT IN (8,12,13,18,20,21))

    SELECT @sqlBetting3 = LEFT(@sqlBetting3, LEN(@sqlBetting3)-10)
END


-- ****** rptKPI_Account ******
DECLARE @sqlAccount nvarchar(max)
IF @stattype IN (0,3)
BEGIN
    --Insert Account stats

    SELECT @sqlAccount = 'INSERT INTO @accountdestination' + char(13) 

    SELECT @sqlAccount = @sqlAccount + 
     'SELECT rptDate, SiteID, ' + CONVERT(varchar(3),StatID) + ' StatID, ' + 
     CASE StatID 
	    WHEN 5 THEN 'sum(UniqueBettorCount)/24'--Average Bettors during days
	    WHEN 6 THEN 'max(PeakBettorCount)'-- Peak concurrent bettors
	    ELSE null
     END + ' Value' + char(13) +
     'FROM @accountsource b with (nolock)' + char(13) +
     'WHERE	rptDate >= ''' + CONVERT(varchar(10),@date, 120) + '''' +
     ' and rptDate < ''' + CONVERT(varchar(10),@date2, 120) + '''' + char(13) +
     'GROUP BY rptDate, SiteID' + char(13) +
     'UNION ALL' + char(13)
    FROM dbo.tblKPI_Stats (NOLOCK) 
    WHERE StatID IN (5,6)

    SELECT @sqlAccount = LEFT(@sqlAccount, LEN(@sqlAccount)-10)
END


IF @stattype IN (0,1) 
BEGIN
    PRINT char(13) + '--Insert Transfer Stats:' + char(13)
	IF (@debug = 1) PRINT @sqlTransfer    
    DELETE FROM dbo.RptKPI_MTD WHERE rptDate >= @date AND rptdate < @date2 AND StatID BETWEEN 1 AND 4
    EXEC sp_executesql @sqlTransfer
END
    
IF @stattype IN (0,2) 
BEGIN
    PRINT char(13) + '--Insert Betting Stats:' + char(13)
    
    DELETE dbo.RptKPI_MTD
    WHERE rptDate >= @date AND rptDate < @date2 
        AND StatID BETWEEN 7 AND 23
        AND SiteID NOT IN (SELECT LicenseeID FROM dbo.Licensees (NOLOCK) WHERE IsDeposit=1)
        
    -- Gen
    PRINT char(13) + '--For Betting Stats (7-11):' + char(13)
    
    SELECT @sqlBetting = REPLACE(@sqlBetting,'@bettingdestination','dbo.rptKPI_MTD')
    SELECT @sqlBetting = REPLACE(@sqlBetting,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
    SELECT @sqlBetting = REPLACE(@sqlBetting,'@ResellerCondition','ResellerID=4') --FDL
    IF (@debug = 1) PRINT @sqlBetting
    EXEC sp_executesql @sqlBetting
    
    -- Gen
    PRINT char(13) + '--For Betting Stats (12-16):' + char(13)
    
    SELECT @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingdestination','dbo.rptKPI_MTD')
    SELECT @sqlBetting2 = REPLACE(@sqlBetting2,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
    SELECT @sqlBetting2 = REPLACE(@sqlBetting2,'@ResellerCondition','ResellerID=4') --FDL
    IF (@debug = 1) PRINT @sqlBetting2
    EXEC sp_executesql @sqlBetting2
    
    -- Gen
    PRINT char(13) + '--For Betting Stats (17-23):' + char(13)
    
    SELECT @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingdestination','dbo.rptKPI_MTD')
    SELECT @sqlBetting3 = REPLACE(@sqlBetting3,'@bettingsource','bodb_LicenseeReport.dbo.rpt_Betting')
    SELECT @sqlBetting3 = REPLACE(@sqlBetting3,'@ResellerCondition','ResellerID=4') --FDL
    IF (@debug = 1) PRINT @sqlBetting3
    EXEC sp_executesql @sqlBetting3
END

IF @stattype IN (0,3)
BEGIN
    PRINT char(13) + '--Insert Account Stats:' + char(13)
    
    IF (@isBA = CONVERT(bit,1))
    BEGIN
        DELETE FROM dbo.RptKPI_MTD_BA WHERE rptDate >= @date AND rptdate < @date2 AND StatID IN (5,6)
	
	    SELECT @sqlAccount = REPLACE(@sqlAccount,'@accountdestination','dbo.rptKPI_MTD_BA')
	    SELECT @sqlAccount = REPLACE(@sqlAccount,'@accountsource','dbo.rptKPI_Account_BA')
    END
    ELSE
    BEGIN
        DELETE FROM dbo.RptKPI_MTD WHERE rptDate >= @date AND rptdate < @date2 AND StatID IN (5,6)
        
        SELECT @sqlAccount = REPLACE(@sqlAccount,'@accountdestination','dbo.rptKPI_MTD')
	    SELECT @sqlAccount = REPLACE(@sqlAccount,'@accountsource','dbo.rptKPI_Account')
    END
    IF (@debug = 1) PRINT @sqlAccount
    EXEC sp_executesql @sqlAccount
END



GO
GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_CreditSites] TO [VNTeam] 
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_RptKPI_MTD_CreditSites] TO [VNTeam]