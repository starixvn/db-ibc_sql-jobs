SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[LRF_Get_LicenseeAll_KPIs]
AS
/*
    Created: 20111012@Don
    Task: 
    DB: DB052.bodb_Licensee

    Revisions:
        -20120518@Jim : add more IsKPIActive condition 
        -20120709@Don: use object view_kpi_labels instead of view_all_labels
    Param's Explanation:

*/
SET NOCOUNT ON

/*SELECT l.LicenseeID SiteID, l.LicenseeName SiteName
FROM dbo.Licensees l (NOLOCK)
WHERE l.IsKPIActive=1--20120518@Jim added
--WHERE LicenseeID <> 13 -- IBC*/
SELECT DISTINCT LicenseeID SiteID, LicenseeName SiteName
FROM dbo.view_kpi_labels (NOLOCK) 
WHERE IsKPIActive=1

SET NOCOUNT OFF



GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseeAll_KPIs] TO [bodbLicenseeNet]  
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_LicenseeAll_KPIs] TO [VNTeam]