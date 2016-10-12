 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

 -- a sample testcase : exec LRF_Get_GroupAll_KPIs
ALTER PROCEDURE [dbo].[LRF_Get_GroupAll_KPIs_NG]
AS
/*
    Created: 20121025@Jim
    Task: 
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
			WHEN lbl.ResellerID = 3 THEN convert(int,999) 
			ELSE 
				CASE
					WHEN IsDeposit = 1 THEN lbl.ResellerID
					ELSE (lbl.ResellerID + 1000)
				END
			END OID	 
	FROM dbo.view_kpi_labels_NG lbl (NOLOCK)
		LEFT JOIN dbo.Resellers r (NOLOCK) ON lbl.ResellerID = r.ResellerID
    WHERE IsKPIActive=1
	)temp
WHERE temp.GroupID<>3--exclude starlit	
ORDER BY temp.oid

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_NG] TO [bodbAdminNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs_NG] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_GroupAll_KPIs_NG] TO [VNTeam]

