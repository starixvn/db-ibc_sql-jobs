/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="1"></info>*/

ALTER FUNCTION [dbo].[f_GetSiteNotOffer] ()
RETURNS TABLE
AS
/*
	Created: 20180807@Elodie	
	Task :  Get list site don't offer
	DB: DBDWCSS/CheckResultDB
	Original:

	Revisions:
		- 20200624@Elodie: Exclude inactive site [Redmine:#136023]
	Param's Explanation:
*/
RETURN
	SELECT site 
	FROM CheckCustDB.dbo.site WITH (NOLOCK)
	WHERE site IN ('IMBC','spotico','Y987')
		OR isLicensee = 1
		OR isActive = 0
	UNION ALL SELECT 'Select'
