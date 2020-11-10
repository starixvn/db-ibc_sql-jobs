/*<info serverAlias="DBAFFN8B-Affiliate_N8B" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ClearLogin]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Clear user login

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DELETE dbo.On_User WITH (ROWLOCK, UPDLOCK)
	WHERE Reload_Time < DATEADD(MINUTE, -30, CURRENT_TIMESTAMP)
END
GO