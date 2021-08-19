CREATE VIEW [dbo].[view_site_list]
AS
/*
    Created: 20110621@Don
    Task: Get list of site
    DB: DB052.bodb_Licensee

    Revisions:
        + 20120314@Don: Fix bug about licensee and label/site have same name
*/

SELECT
    CASE
        WHEN lic.LicenseeName IS NOT NULL THEN lic.LicenseeID
        ELSE (1000 + s.siteID)
    END AS SiteID
    ,s.site AS SiteName
    ,s.siteID AS IbcSiteID
    --,tblS.siteID AS DwSiteID
FROM bodb02.dbo.Site s (NOLOCK)
    LEFT JOIN dbo.Licensees lic WITH(NOLOCK) ON s.site = lic.LicenseeName AND lic.IsDeposit=1
    --LEFT JOIN DBDW2.bodb_Account.dbo.tbl_Site tblS (NOLOCK) ON s.site = tblS.site -- for production
