 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


CREATE PROCEDURE [dbo].[LRF_Get_LicenseeAll_KPIs_NG]
AS
/*
    Created: 20121025@Jim
    Task: 
    DB: DB052.bodb_Licensee
	Original:LRF_Get_LicenseeAll_KPIs
    Revisions:
        
    Param's Explanation:

*/
SET NOCOUNT ON

SELECT DISTINCT LicenseeID SiteID, LicenseeName SiteName
FROM dbo.view_kpi_labels_NG (NOLOCK) 
WHERE IsKPIActive=1

SET NOCOUNT OFF
GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseeAll_KPIs_NG] TO [bodbAdminNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseeAll_KPIs_NG] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_LicenseeAll_KPIs_NG] TO [VNTeam]



