CREATE VIEW [dbo].[view_kpi_labels]
AS
/*
    Created: 20120709@Don
    Task: Get list of KPI active labels
    DB: DB052.bodb_Licensee

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
FROM dbo.LicenseeReseller lr (NOLOCK)
	LEFT JOIN dbo.Licensees l (NOLOCK) ON lr.licenseeid = l.licenseeid
	LEFT JOIN dbo.Labels lbl (NOLOCK) ON lr.licenseeid = lbl.licenseeid
	LEFT JOIN dbo.SystemLicensee syslic (NOLOCK) ON lr.licenseeid = syslic.licenseeid
WHERE 
    lr.resellerid<>6 
    AND syslic.systemid=5
