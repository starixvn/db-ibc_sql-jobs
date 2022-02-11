/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_SMP_MarketSelection14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBPRO.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Event_Copy
	
	Revisions:
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId
	FROM	dbo.SMP_MarketSelection14 AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);
END
