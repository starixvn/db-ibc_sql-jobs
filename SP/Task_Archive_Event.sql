USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_Event]    Script Date: 07/19/2015 22:21:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_Event]
	@winlostdate datetime
AS
/*
	DB: DB02.bodb02
	Revisions:    
		- 20101229@Viet: Add moving for data from BingoBall table
		- 20110715@Vivi(DB02): Add moving for data from outright14.ProgramDate
		- 20130520@Victor(DB02): Add moving for data from VSOutright14.eventdate
		- 20140911@Lukas: add table MatchMaxbet_bk 
		- 20141006@Lukas: remove table SS_GameState_bk
		- 20141024@Lukas: add table ResultDetail14
		- 20141225@Jamie: Add OtherInfo into ResultDetail_bk
		- 20150506@Victor(DB02): Add ParentID to Match14 and Match_BK
		- 20150626@Cooper(DB02): Add match_remark table Arcihve column 'HomeSubstitutes,AwaySubstitutes,StartTeam,HomePenalty,AwayPenalty'
		- 20150703@Cooper(DB02): Add match_remark table Arcihve column 'HomeYellowCard,AwayYellowCard'
		- 20150720@Sophia: Add ResultDetail3rd14 table
		- 20160120@Sophia: Add EventInfo3rd_bk table for Cockfighting 
 */

	INSERT INTO DB06.bodb_archive.dbo.odds_bk
		SELECT * FROM odds14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_archive.dbo.match_bk
		SELECT
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore,
			finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime,
			hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp,
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, GlobalShowTime, ParentID
		FROM match14 WHERE eventdate = @winlostdate

	INSERT INTO DB06.bodb_archive.dbo.bingoBall_bk
		([Matchid], [Seq], [Number], [UpdateTime])
	SELECT
		[Matchid], [Seq], [Number], [UpdateTime]
	FROM BingoBall14
	WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)
	
	--INSERT INTO DB06.bodb_archive.dbo.SS_GameState_bk
	--	(Matchid, ResultKey, ResultValue)
	--SELECT
	--	Matchid, ResultKey, ResultValue
	--FROM SS_GameState14
	--WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)
	
	INSERT INTO DB06.bodb_archive.dbo.outright_bk
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
        DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, 
		FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadHeat)
		SELECT
			orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, 
			DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, 
			ProgramDate, IsDeadHeat
		FROM outright14 WHERE eventdate = @winlostdate
		
		
	INSERT INTO DB06.bodb_archive.dbo.VSOutright_bk
		(Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, 
		Lane, MaxBet, Placing, Creator, EventStatus )		
	select 	
		Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, 
		Lane, MaxBet, Placing, Creator, EventStatus
	from VSOutright14 where eventdate = @winlostdate 

	INSERT INTO DB06.bodb_Archive.dbo.match_remark
	(
	[matchid], [calculate], [multiple], [calrefund], [refund], [calStatus], [IsTotalBetDenied_1], [IsTotalBetDenied_3], [IsTotalBetDenied_7], [IsTotalBetDenied_8],
	[LiveTimer], [HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast], [IsTotalBetDenied_20], [IsTotalBetDenied_21], [IsNeutral], [StreamingID], [IsInternal], [IsHTCal],
	[LiveDeleteChecker], [HomeColor], [AwayColor], [ConfirmHT], [ConfirmFT], [PausePeriod], [TimerSuspend], [IsPending], [isUndecided], [StdDelBetCheck],
	HomeSubstitutes,AwaySubstitutes,StartTeam,HomePenalty,AwayPenalty,HomeYellowCard,AwayYellowCard
	)
	SELECT
	[matchid], [calculate], [multiple], [calrefund], [refund], [calStatus], [IsTotalBetDenied_1], [IsTotalBetDenied_3], [IsTotalBetDenied_7], [IsTotalBetDenied_8],
	[LiveTimer], [HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast], [IsTotalBetDenied_20], [IsTotalBetDenied_21], [IsNeutral], [StreamingID], [IsInternal], [IsHTCal],
	[LiveDeleteChecker], [HomeColor], [AwayColor], [ConfirmHT], [ConfirmFT], [PausePeriod], [TimerSuspend], [IsPending], [isUndecided], [StdDelBetCheck],
	HomeSubstitutes,AwaySubstitutes,StartTeam,HomePenalty,AwayPenalty,HomeYellowCard,AwayYellowCard
	FROM match_remark
	WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_Archive.dbo.[MatchMaxbet_bk](MatchId, BetType, Maxbet, OperatorId)
	SELECT MatchId, BetType, Maxbet, OperatorId
	FROM matchMaxbet14 WITH(NOLOCK)
	WHERE matchid IN (SELECT MatchID from Match14 where eventdate = @winlostdate)
	
	INSERT INTO DB06.bodb_Archive.dbo.[ResultDetail_bk](MatchId, ResourceId, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateDate, LastModifyDate, CreateBy, LastModifyBy,OtherInfo)
	SELECT MatchId, ResourceId, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateDate, LastModifyDate, CreateBy, LastModifyBy,OtherInfo
	FROM ResultDetail14 WITH(NOLOCK)
	WHERE matchid IN (SELECT MatchID from Match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_Archive.dbo.[ResultDetail3rd_bk](ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate)
	SELECT ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate
	FROM ResultDetail3rd14 WITH(NOLOCK)
	WHERE matchid IN (SELECT MatchID from Match14 where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_Archive.dbo.[EventInfo3rd_bk](EventInfo3rdId,ArenaID,FightNo,EventDate,HomeOwner,AwayOwner)
	SELECT EventInfo3rdId,ArenaID,FightNo,EventDate,HomeOwner,AwayOwner
	FROM dbo.EventInfo3rd14 WITH(NOLOCK)
	WHERE EventDate = @winlostdate
	
	
	
	DELETE FROM odds14  WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM BingoBall14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM match_Remark WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	--DELETE FROM SS_GameState14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM ResultDetail14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	DELETE FROM ResultDetail3rd14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	
	DELETE FROM outright14 WHERE eventdate = @winlostdate
	
	DELETE FROM VSOutright14 WHERE eventdate = @winlostdate
	DELETE FROM EventInfo3rd14 WHERE Eventdate = @winlostdate

	DELETE FROM match14 WHERE eventdate = @winlostdate
	
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Event] TO [vnteam] AS [dbo]
GO
