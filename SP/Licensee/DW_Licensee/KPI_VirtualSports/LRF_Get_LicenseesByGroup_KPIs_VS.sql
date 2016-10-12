  set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER  PROCEDURE [dbo].[LRF_Get_LicenseesByGroup_KPIs_VS]
    @GroupID int
AS
/*
    Created: 20121109@Jim
    Task: OWA - Add Virtual Sport data to KPI report
    DB: DB052.bodb_Licensee
	Original:LRF_Get_LicenseesByGroup_KPIs

    Revisions:
      
        
    Param's Explanation:

*/
SET NOCOUNT ON

SELECT LabelID SiteID, LabelName SiteName 
FROM dbo.view_kpi_labels_VS (NOLOCK)
WHERE ResellerID = @GroupID AND IsKPIActive = 1
ORDER BY SiteID 

SET NOCOUNT OFF
GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseesByGroup_KPIs_VS] TO [bodbAdminNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseesByGroup_KPIs_VS] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_LicenseesByGroup_KPIs_VS] TO [VNTeam]




