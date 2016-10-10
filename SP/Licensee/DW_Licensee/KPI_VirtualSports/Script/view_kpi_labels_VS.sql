USE [bodb_licensee]
GO
/****** Object:  View [dbo].[view_kpi_labels_VS]    Script Date: 11/12/2012 10:16:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  VIEW [dbo].[view_kpi_labels_VS]
AS
/*
    Created: 20121109@Jim
    Task:  OWA - Add Virtual Sport data to KPI report
    DB: DB052.bodb_Licensee
	Original:view_kpi_labels
    Revisions:
    
*/

SELECT 
     lr.resellerid
    ,lr.licenseeid
    ,lr.TnxRate
    ,l.LicenseeName
    ,l.IsDeposit
	,CASE WHEN lbl.licenseeid is null THEN l.licenseeid ELSE lbl.LabelID END LabelID
	,CASE WHEN lbl.licenseeid is null THEN l.LicenseeName ELSE lbl.LabelName END LabelName
	,lbl.IsKPISummary
	,syslic.IsActive IsKPIActive
	,CASE WHEN lbl.licenseeid is null THEN l.AffectedDate ELSE lbl.AffectedDate END AffectedDate
FROM dbo.LicenseeProduct3rd lp(NOLOCK)
	INNER JOIN dbo.LicenseeReseller lr (NOLOCK) ON lp.LicenseeID=lr.LicenseeID
	LEFT  JOIN dbo.Licensees l (NOLOCK) ON lr.licenseeid = l.licenseeid
	LEFT  JOIN dbo.Labels lbl (NOLOCK) ON lr.licenseeid = lbl.licenseeid
	LEFT  JOIN dbo.SystemLicensee syslic (NOLOCK) ON lr.licenseeid = syslic.licenseeid
WHERE 
    lr.resellerid <> 6
	AND lp.ProductID=5
    AND syslic.systemid=5
GO
GRANT SELECT ON [dbo].view_kpi_labels_VS TO [bodbAdminNet]
GRANT SELECT ON [dbo].view_kpi_labels_VS TO [bodbLicenseeNet]
GRANT SELECT ON [dbo].view_kpi_labels_VS TO [VNTeam]
