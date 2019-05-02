/*<info serverAlias="DBPOL-NAP_UserControl" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_EAS_ClearLogin]	
AS
/*
	Created:  20121116@Dan
	Task: EAS - Clear Login
	DB: DBPOL/NAP_UserControl
	Original SP:
	
	Revisions:
		- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
*/
BEGIN
	SET NOCOUNT ON
	DELETE FROM eaOn_User WITH (UPDLOCK,ROWLOCK)
	WHERE	reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP)
END
GO
