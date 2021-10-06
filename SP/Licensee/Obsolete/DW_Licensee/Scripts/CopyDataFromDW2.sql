/*
    Created: 20110621@Don
    Task: Import data from DW to LicenseeDB
    DB: DB052.bodb_Licensee

    Revisions:

*/

-- ****** Copy Data ******
/* Just run one time */
-- tblKPI_Stats
INSERT INTO bodb_Licensee.dbo.tblKPI_Stats(StatID,StatName)
    SELECT StatID,StatName
    FROM dbdw2.bodb_KPI.dbo.tblKPI_Stats WITH(NOLOCK)
    
-- tblKPI_Budgets
INSERT INTO bodb_Licensee.dbo.tblKPI_Budgets([Date],GroupID,StatID,BudgetAmount)
    SELECT [Date],GroupID,StatID,BudgetAmount
    FROM dbdw2.bodb_KPI.dbo.tblKPI_Budgets WITH(NOLOCK)
/* End - Just run one time */



DECLARE @date datetime, @date2 datetime
SELECT @date = '', @date2 = ''

-- tbl_Customer_Account
INSERT INTO bodb_Licensee.dbo.tbl_Customer_Account(
        transid,refno,custid,currency,transdate,amount,creator,TransDesc,deleted,
        balanceduppreviousday,OtherCustid,recommend,mrecommend,srecommend,transtype)
    SELECT 
        transid,refno,custid,currency,transdate,amount,creator,TransDesc,deleted,
        balanceduppreviousday,OtherCustid,recommend,mrecommend,srecommend,transtype
    FROM dbdw2.bodb_KPI.dbo.tbl_Customer_Account WITH(NOLOCK)
    WHERE transdate >= @date AND transdate < @date2

-- rptKPI_Transfer
INSERT INTO bodb_Licensee.dbo.rptKPI_Transfer(rptDate,SiteID,CurrencyID,TransferInCount,FirstTransferInAmt,FirstTransferInCount,TransferOutCount)
    SELECT rptDate,SiteID,CurrencyID,TransferInCount,FirstTransferInAmt,FirstTransferInCount,TransferOutCount
    FROM dbdw2.bodb_KPI.dbo.rptKPI_Transfer WITH(NOLOCK)
    WHERE rptDate >= @date AND rptDate < @date2

-- rpt_Betting
INSERT INTO bodb_Licensee.dbo.rpt_Betting(rptDate,SiteID,Bettype,LeagueID,CurrencyID,Status,IsLive,BetCount,MemberCount,Turnover,WinLoss)
    SELECT rptDate,SiteID,Bettype,LeagueID,CurrencyID,Status,IsLive,BetCount,MemberCount,Turnover,WinLoss
    FROM dbdw2.bodb_KPI.dbo.rptKPI_Betting WITH(NOLOCK)
    WHERE rptDate >= @date AND rptDate < @date2

-- rptKPI_Account
INSERT INTO bodb_Licensee.dbo.rptKPI_Account(rptDate,SiteID,[Hour],UniqueBettorCount,PeakBettorCount)
    SELECT rptDate,SiteID,[Hour],UniqueBettorCount,PeakBettorCount
    FROM dbdw2.bodb_KPI.dbo.rptKPI_Account WITH(NOLOCK)
    WHERE rptDate >= @date AND rptDate < @date2
    
-- rptKPI_MTD
INSERT INTO bodb_Licensee.dbo.rptKPI_MTD(rptDate,SiteID,StatID,MonthToDate)
    SELECT rptDate,SiteID,StatID,MonthToDate
    FROM dbdw2.bodb_KPI.dbo.rptKPI_MTD WITH(NOLOCK)
    WHERE rptDate >= @date AND rptDate < @date2



-- ****** Update SiteID and StatusID ******

-- rptKPI_Transfer
UPDATE tran WITH(ROWLOCK,UPDLOCK) 
SET trans.SiteID = site.SiteID
FROM bodb_Licensee.dbo.rptKPI_Transfer trans
    LEFT JOIN bodb_Licensee.dbo.view_site_list_dw site (NOLOCK) ON trans.SiteID = site.DwSiteID
WHERE rptDate >= @date AND rptDate < @date2

-- rpt_Betting
UPDATE bet WITH(ROWLOCK,UPDLOCK)
SET 
    bet.SiteID = site.SiteID,
    bet.Status = status.StatusID
FROM bodb_Licensee.dbo.rpt_Betting bet 
    LEFT JOIN bodb_Licensee.dbo.view_site_list_dw site (NOLOCK) ON bet.SiteID = site.DwSiteID
    LEFT JOIN bodb_Licensee.dbo.view_status_list status (NOLOCK) ON bet.Status = status.DwStatusID
WHERE rptDate >= @date AND rptDate < @date2

-- rptKPI_Account
UPDATE acc WITH(ROWLOCK,UPDLOCK)
SET acc.GroupID = site.SiteID
FROM bodb_Licensee.dbo.rptKPI_Account acc 
    LEFT JOIN bodb_Licensee.dbo.view_site_list_dw site (NOLOCK) ON acc.SiteID = site.DwSiteID
WHERE rptDate >= @date AND rptDate < @date2

-- rptKPI_MTD
UPDATE mtd WITH(ROWLOCK,UPDLOCK)
SET mtd.SiteID = site.SiteID
FROM bodb_Licensee.dbo.rptKPI_MTD mtd
    LEFT JOIN bodb_Licensee.dbo.view_site_list_dw site (NOLOCK) ON mtd.SiteID = site.DwSiteID
WHERE rptDate >= @date AND rptDate < @date2

-- ****** Update GroupID ******

---- tblKPI_Budgets
UPDATE acc WITH(ROWLOCK,UPDLOCK) -- OneNet
SET acc.GroupID = 11
FROM bodb_Licensee.dbo.tblKPI_Budgets acc 
WHERE rptDate >= @date AND rptDate < @date2
    and GroupID = 1
    
UPDATE acc WITH(ROWLOCK,UPDLOCK) -- GWI
SET acc.GroupID = 1
FROM bodb_Licensee.dbo.tblKPI_Budgets acc 
WHERE rptDate >= @date AND rptDate < @date2
    and GroupID = 2
    
UPDATE acc WITH(ROWLOCK,UPDLOCK) -- OneNet
SET acc.GroupID = 2
FROM bodb_Licensee.dbo.tblKPI_Budgets acc 
WHERE rptDate >= @date AND rptDate < @date2
    and GroupID = 11