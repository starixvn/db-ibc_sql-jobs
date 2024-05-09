/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ClearLogin]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Clear user login

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	DELETE dbo.On_User WITH (ROWLOCK, UPDLOCK)
	WHERE Reload_Time < DATEADD(MINUTE, -30, CURRENT_TIMESTAMP)
END
GO