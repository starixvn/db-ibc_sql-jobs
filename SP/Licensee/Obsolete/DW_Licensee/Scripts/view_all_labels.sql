CREATE VIEW [dbo].[view_all_labels]
AS
/*
    Created: 20120608@Don
    Task: Get list of KPI active labels
    DB: DB052.bodb_Licensee

    Revisions:
    
*/

SELECT lr.resellerid,lr.licenseeid,lr.TnxRate,l.LicenseeName,l.IsDeposit,
	CASE WHEN lbl.licenseeid is null THEN l.licenseeid ELSE lbl.LabelID END LabelID,
	CASE WHEN lbl.licenseeid is null THEN l.LicenseeName ELSE lbl.LabelName END LabelName,
	lbl.IsKPISummary,
	l.IsKPIActive,
	CASE WHEN lbl.licenseeid is null THEN l.AffectedDate ELSE lbl.AffectedDate END AffectedDate
FROM dbo.LicenseeReseller lr (NOLOCK)
	LEFT JOIN dbo.Licensees l (NOLOCK) ON lr.licenseeid = l.licenseeid
	LEFT JOIN dbo.Labels lbl (NOLOCK) ON lr.licenseeid = lbl.licenseeid
WHERE lr.resellerid<>6
