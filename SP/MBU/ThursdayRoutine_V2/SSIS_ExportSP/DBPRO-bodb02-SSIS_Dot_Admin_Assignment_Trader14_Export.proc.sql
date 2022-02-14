/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Dot_Admin_Assignment_Trader_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBPRO.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Event_Copy
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	SET NOCOUNT ON;
	
	SELECT	ID, matchid, bettype, liveindicator, Detail_X, Detail_Y, Detail_Z, Type, TraderID, SuspenderID, UpdatedTime, UpdatedUser
	FROM	dbo.Dot_Admin_Assignment_Trader AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);
END
GO
