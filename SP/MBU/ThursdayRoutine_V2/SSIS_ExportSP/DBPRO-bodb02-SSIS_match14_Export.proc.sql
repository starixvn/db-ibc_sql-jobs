/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_match14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBPRO.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Event_Copy
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220419@Bobby: remove tstamp column [Redmine: #166146]
 */
 BEGIN
	SET NOCOUNT ON;
	
	SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime
		,	hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral
		,	GoalRecord, GlobalShowTime, ParentID, ShowTimeDT,ChildMatchType
	FROM	dbo.match14 AS t1 WITH (NOLOCK)
	WHERE	t1.eventdate = @winlostdate;
END
GO
