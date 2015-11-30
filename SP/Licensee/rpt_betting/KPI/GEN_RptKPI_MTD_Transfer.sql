USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GEN_RptKPI_MTD_Transfer]    Script Date: 01/28/2015 04:41:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.GEN_RptKPI_MTD_Transfer    Script Date: 8/22/2012 11:20:22 AM ******/

CREATE PROCEDURE [dbo].[GEN_RptKPI_MTD_Transfer]
    @date datetime, 
    @date2 datetime
AS
/*
Created: 20120810@Don
Task: Generate data into GEN_RptKPI_MTD from rptKPI_Transfer
DB: DB052.bodb_Licensee

Revisions:
    
Param's Explanation:

*/

DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID IN (1,2,3,4) 

INSERT INTO dbo.rptKPI_MTD_Cross
    SELECT transfer.rptDate, transfer.SiteID, transfer.CurrencyID, cast(f.StatID as int) StatID, f.MTD
    FROM 
        (
            SELECT 
                 b.rptDate
                ,b.SiteID
                ,b.CurrencyID
                ,FirstTransferInCount
                ,FirstTransferInAmt
                ,TransferInCount
                ,TransferOutCount
            FROM dbo.rptKPI_Transfer b (NOLOCK)
            WHERE b.rptDate >= @date AND b.rptDate < @date2
        ) transfer CROSS APPLY (
            SELECT 1, FirstTransferInCount UNION ALL
            SELECT 2, FirstTransferInAmt UNION ALL
            SELECT 3, TransferInCount UNION ALL
            SELECT 4, TransferOutCount
        ) f(StatID,MTD)
GO

GRANT EXECUTE ON [dbo].[GEN_RptKPI_MTD_Transfer] TO [bodbLicenseeNet] AS [dbo]
GO


