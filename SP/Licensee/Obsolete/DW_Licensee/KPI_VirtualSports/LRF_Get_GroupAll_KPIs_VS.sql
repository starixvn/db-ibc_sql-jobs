  set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

 -- a sample testcase : exec LRF_Get_GroupAll_KPIs
ALTER PROCEDURE [dbo].[LRF_Get_GroupAll_KPIs_VS]
AS
/*
    Created: 20121109@Jim
    Task: OWA - Add Virtual Sport data to KPI report
    DB: DB052.bodb_Licensee
	Original:LRF_Get_GroupAll_KPIs
    Revisions:
    
    Param's Explanation:

*/
SET NOCOUNT ON

SELECT temp.GroupID,temp.GroupName,temp.GroupType
FROM (
	SELECT  DISTINCT
			lbl.ResellerID GroupID,r.ResellerName GroupName,
			1 AS  GroupType,
			CASE
				WHEN IsDeposit = 1 THEN lbl.ResellerID
				ELSE (lbl.ResellerID + 1000)
			END OID	 
	FROM dbo.view_kpi_labels_VS lbl (NOLOCK)
		LEFT JOIN dbo.Resellers r (NOLOCK) ON lbl.ResellerID = r.ResellerID
    WHERE lbl.IsKPIActive=1
		  --AND lbl.resellerid IN (4,8)-- just for FDL,PIH
	)temp
WHERE temp.GroupID<>3--exclude starlit	
ORDER BY temp.oid

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_VS] TO [bodbAdminNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_VS] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_GroupAll_KPIs_VS] TO [VNTeam]

