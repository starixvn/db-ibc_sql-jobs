/*<info serverAlias="DBONUSER-IPDB" executers="" viewers="" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[f_IP_GetCountryName]
(
	@IPList NVARCHAR(MAX) = ''
)
RETURNS TABLE
AS
/*
	Created by: Malcolm
	Date: 2023-02-21
	Task: Get IP Info 
	DB: DBONUSER/IPDB 

	Revisions:	
		- 20230221@Malcolm: Get country Name [RedmineId : #183895]
*/

RETURN
(
	SELECT f.value AS IP, c.CountryName
	FROM STRING_SPLIT(@IPList, ',') f
	CROSS APPLY (
		SELECT dbo.f_IP_GetIPInfo_Full(f.value) AS CountryName
	) AS c
	WHERE f.value <> ''
)
GO