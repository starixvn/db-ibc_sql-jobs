IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GEN_RptKPI_MTD_Account]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GEN_RptKPI_MTD_Account]
GO

CREATE PROCEDURE [dbo].[GEN_RptKPI_MTD_Account]
    @date datetime, 
    @date2 datetime,
    @isBA bit = 0
AS
/*
Created: 20120810@Don
Task: Generate data into GEN_RptKPI_MTD from rptKPI_Account
DB: DB052.bodb_Licensee

Revisions:
    
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
GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Account] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_RptKPI_MTD_Account] TO [VNTeam]
