/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Intg_OddsFeed_SettlementAction_Outright_Export]
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
	
	SELECT	ActionId, ActionType, OrId, LeagueId, TeamId, Status, IsDeadheat, Deadheat, CreateTime
	FROM	dbo.Intg_OddsFeed_SettlementAction_Outright AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.outright14 AS t2 WITH (NOLOCK) WHERE t1.orid = t2.orid AND t2.eventdate = @winlostdate);
END
GO
