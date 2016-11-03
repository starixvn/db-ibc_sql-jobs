USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_RptKPI_MTD_Account]
    @date datetime, 
    @date2 datetime,
    @isBA bit = 0
AS
/*
Created: 20120810@Don
Task: Generate data into GEN_RptKPI_MTD from rptKPI_Account
DB: DBLIC.bodb_LicenseeReport

Revisions:
20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
    
Param's Explanation:

*/

IF @isBA = 0
BEGIN

    DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID IN (5,6)

    INSERT INTO dbo.rptKPI_MTD_Cross
        SELECT account.rptDate, account.SiteID, account.CurrencyID, cast(f.StatID as int) StatID, f.MTD
        FROM 
            (
                SELECT b.rptDate, b.SiteID, -1 CurrencyID, 
                    sum(UniqueBettorCount)/24 AverageBettorsDuringDays, 
                    max(PeakBettorCount) PeakConcurrentBettors
                FROM dbo.rptKPI_Account b (NOLOCK)
                WHERE b.rptDate >= @date AND b.rptDate < @date2
                GROUP BY b.rptDate, b.SiteID
            ) account CROSS APPLY (
                SELECT 5, AverageBettorsDuringDays UNION ALL
                SELECT 6, PeakConcurrentBettors
            ) f(StatID,MTD)

END
ELSE
BEGIN

    DELETE dbo.rptKPI_MTD_BA_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID IN (5,6)

    INSERT INTO dbo.rptKPI_MTD_BA_Cross
        SELECT account.rptDate, account.SiteID, account.CurrencyID, cast(f.StatID as int) StatID, f.MTD
        FROM 
            (
                SELECT b.rptDate, b.SiteID, -1 CurrencyID, 
                    sum(UniqueBettorCount)/24 AverageBettorsDuringDays, 
                    max(PeakBettorCount) PeakConcurrentBettors
                FROM dbo.rptKPI_Account_BA b (NOLOCK)
                WHERE b.rptDate >= @date AND b.rptDate < @date2
                GROUP BY b.rptDate, b.SiteID
            ) account CROSS APPLY (
                SELECT 5, AverageBettorsDuringDays UNION ALL
                SELECT 6, PeakConcurrentBettors
            ) f(StatID,MTD)
            
END
GO
GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Account] TO [bodbLicenseeNet] AS [dbo]