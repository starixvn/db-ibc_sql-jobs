/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_match_remark_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBPRO.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Event_Copy
	
	Revisions:
		- 20130831@Bobby: Init
		- 20230309@Brice: MBU for New Column NoHTScore on Match_Remark Table #181415
 */
 BEGIN
	SET NOCOUNT ON;
	
	SELECT	matchid, calculate, multiple, calrefund, refund, calStatus, IsTotalBetDenied_1, IsTotalBetDenied_3, IsTotalBetDenied_7, IsTotalBetDenied_8, LiveTimer, HomeRedCard, AwayRedCard
		,	LivePeriod, HedgeForecast, IsTotalBetDenied_20, IsTotalBetDenied_21, IsNeutral, StreamingID, IsInternal, IsHTCal, LiveDeleteChecker, HomeColor, AwayColor, ConfirmHT, ConfirmFT
		,	PausePeriod, TimerSuspend, IsPending, isUndecided, StdDelBetCheck, HomeSubstitutes, AwaySubstitutes, StartTeam, HomePenalty, AwayPenalty, HomeYellowCard, AwayYellowCard
		,	Tier, OfferLive, CommGroup,NoHTScore
	FROM	dbo.match_remark AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);
END