/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus,bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Get_SiteDBGroupID] 
AS
/*
	Created: 20220817@Tina
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220817@Tina: Create [RedmineID: #158293]
*/
BEGIN
	SELECT dbo.f_Get_SiteDBGroupID() AS SiteDBGroupId 
END