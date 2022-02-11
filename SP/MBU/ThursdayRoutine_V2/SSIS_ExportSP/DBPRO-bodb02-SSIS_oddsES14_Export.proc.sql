/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_oddsES14_Export]
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
	
	SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk
		, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category
		, IncreaseMaxbet, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
		, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
		, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
		, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
		, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
		, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
		, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
	FROM	dbo.oddsES14 AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);
END
GO
