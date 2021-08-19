USE [bodb_Licensee]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DW_View_Site_List]') AND type in (N'V'))
DROP VIEW [dbo].[DW_View_Site_List]
GO

CREATE VIEW [dbo].[DW_View_Site_List]
AS
/*
    Created: 20120712@Don
    Task: Get list of site
    DB: bodb_Licensee

    Revisions:
    
*/

SELECT
     lic.LicenseeID AS SiteID
    ,s.site AS SiteName
    ,s.siteID AS IbcSiteID
FROM bodb02.dbo.Site s WITH(NOLOCK)
    LEFT JOIN dbo.Licensees lic WITH(NOLOCK) ON s.site = lic.LicenseeName
WHERE lic.IsDeposit=1



GO
GRANT VIEW DEFINITION ON [dbo].[DW_View_Site_List] TO [VNTeam]  