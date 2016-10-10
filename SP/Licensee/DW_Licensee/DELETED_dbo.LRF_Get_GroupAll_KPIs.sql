SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 -- a sample testcase : exec LRF_Get_GroupAll_KPIs
ALTER PROCEDURE [dbo].[LRF_Get_GroupAll_KPIs]
AS
/*
    Created: 20111012@Don
    Task: 
    DB: DB052.bodb_Licensee

    Revisions:
        - 20120307@Don:
        - 20120518@Jim: add IsKPIActive condition 
        - 20120709@Don: use object view_kpi_labels instead of view_all_labels
    Param's Explanation:

*/
SET NOCOUNT ON

SELECT temp.GroupID,temp.GroupName
FROM (
	SELECT DISTINCT lbl.ResellerID GroupID,r.ResellerName GroupName,
		CASE 
			WHEN lbl.ResellerID = 3 THEN convert(int,999) 
			ELSE 
				CASE
					WHEN IsDeposit = 1 THEN lbl.ResellerID
					ELSE (lbl.ResellerID + 1000)
				END
		END OID
	FROM dbo.view_kpi_labels lbl (NOLOCK)
		LEFT JOIN dbo.Resellers r (NOLOCK) ON lbl.ResellerID = r.ResellerID
    WHERE IsKPIActive=1
	)temp
ORDER BY temp.oid

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_Get_GroupAll_KPIs] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_GroupAll_KPIs] TO [VNTeam]
