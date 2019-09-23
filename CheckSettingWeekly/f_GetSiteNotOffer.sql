USE [CheckResultDB]
GO

ALTER FUNCTION [dbo].[f_GetSiteNotOffer] ()
RETURNS  @tblSite TABLE( site VARCHAR(10))
AS
/*
	Created: 20180807@Elodie	
	Task :  Get list site don't offer
	DB: DBDWCSS/CheckResultDB
	Original:

	Revisions:
	Param's Explanation:
*/
BEGIN

	INSERT INTO @tblSite (site)	
	SELECT site 
	FROM CheckCustDB.dbo.site WITH (NOLOCK)
	WHERE site IN ('IMBC','spotico','Y987')
		OR isLicensee = 1
		OR isActive = 0
	UNION ALL SELECT 'Select'

	RETURN
END