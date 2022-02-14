/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_EventInfo3rd14_Export]
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
	
	SELECT	EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner
	FROM	dbo.EventInfo3rd14 AS t1 WITH (NOLOCK)
	WHERE	t1.eventdate = @winlostdate;
END
GO
