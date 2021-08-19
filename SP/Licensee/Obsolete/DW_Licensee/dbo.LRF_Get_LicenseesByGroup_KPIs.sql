SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[LRF_Get_LicenseesByGroup_KPIs]
    @GroupID int
AS
/*
    Created: 20111012@Don
    Task: 
    DB: DB052.bodb_Licensee

    Revisions:
        - 20120305@Don: Adapt for restructuring Licensees and Labels/Sites
        - 20120518@Don: Include SunGame licensee to result
		- 20180518@Jim: add more IsKPIActive=1 condition 
		- 20120709@Don: use object view_kpi_labels instead of view_all_labels
        
    Param's Explanation:

*/
SET NOCOUNT ON

SELECT LabelID SiteID, LabelName SiteName 
FROM dbo.view_kpi_labels (NOLOCK)
WHERE ResellerID = @GroupID AND IsKPIActive = 1
ORDER BY SiteID 

SET NOCOUNT OFF



GO
GRANT EXECUTE ON [dbo].[LRF_Get_LicenseesByGroup_KPIs] TO [bodbLicenseeNet]  
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_LicenseesByGroup_KPIs] TO [VNTeam]