set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER  PROCEDURE [dbo].[LRF_Get_GroupAll_KPIs_LC]
AS
/*
    Created: 20121109@Jim
    Task: OWA - Add Live Casino data to KPI report
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
			CASE WHEN lbl.ResellerID IN(5,7,9) THEN 0
				 WHEN lbl.ResellerID IN (4,8)  THEN 1
				 WHEN lbl.ResellerID IN (1,2)  THEN 2
				 END AS GroupType,
			CASE
				WHEN IsDeposit = 1 THEN lbl.ResellerID
				ELSE (lbl.ResellerID + 1000)
			END OID	 
	FROM dbo.view_kpi_labels_LC lbl (NOLOCK)
		LEFT JOIN dbo.Resellers r (NOLOCK) ON lbl.ResellerID = r.ResellerID
    WHERE lbl.IsKPIActive=1
		  --AND lbl.resellerid IN (4,8)-- just for FDL,PIH
	)temp
WHERE temp.GroupID<>3--exclude starlit	
ORDER BY temp.oid

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_LC] TO [bodbAdminNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_LC] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_GroupAll_KPIs_LC] TO [VNTeam]