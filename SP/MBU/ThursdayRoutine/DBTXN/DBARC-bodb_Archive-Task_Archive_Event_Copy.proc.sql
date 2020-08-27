SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Event_Copy
						@winlostdate		DATETIME
					,	@TableName			NVARCHAR(128)	= ''
AS
/*
	Created:	20190318@Helen
	Task:		Archive event runner on DBARC - [Redmine: #110447]
	Database:	DBARC.bodb_Archive
	Original:	DBPRO/bodb02/Task_Archive_Event

	Revisions:
		- 20190318@Helen:	Initialize - archive event timeout issue - [Redmine: #110447]
		- 20190925@Billy:	Add [Dot_Admin_Assignment_Trader] table - [Redmine: #117014]
		- 20190827@Billy:	Add [oddsOS] & [ResultDetailOS] tables - [Redmine: #119257]
		- 20200504@Patrick: Add more field for oddsES/oddsES14/oddsES_bk - [Redmine: #133538]
		- 20200622@Patrick: Add more table VSRaceInfo [Redmine: #135963]
		- 20200729@Brice:	Add table ProviderExternalResultDetailES [Redmine: #138380]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@Query		NVARCHAR(MAX)
		;

	---------------Table 1: odds_bk --------------------
	IF	@TableName = N'odds_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.odds_bk
	(	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc
	,	odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1
	,	maxstake2, minstake1, minstake2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, comx, com2
	,	cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, commaxbet
	,	csmaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44
	,	bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, hometotal, awaytotal, sporttype
	,	tstamp, Resourceid, ResultKey, cs99, bal99)
SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc
	,	odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1
	,	maxstake2, minstake1, minstake2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, comx, com2
	,	cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, commaxbet
	,	csmaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44
	,	bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, hometotal, awaytotal, sporttype
	,	tstamp, Resourceid, ResultKey, cs99, bal99
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc
	,	odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1
	,	maxstake2, minstake1, minstake2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, comx, com2
	,	cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, commaxbet
	,	csmaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44
	,	bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, hometotal, awaytotal, sporttype
	,	tstamp, Resourceid, ResultKey, cs99, bal99
FROM	bodb02.dbo.odds14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 2: match_bk --------------------
	-- Need confirm: no sync column [AutoSetting]?
	ELSE IF	@TableName = N'match_bk'
	BEGIN;
		SELECT	@Query = '';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.match_bk
	(	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime
	,	hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral
	,	GoalRecord, GlobalShowTime, ParentID, ShowTimeDT)
SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime
	,	hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral
	,	GoalRecord, GlobalShowTime, ParentID, ShowTimeDT
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime
	,	hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral
	,	GoalRecord, GlobalShowTime, ParentID, ShowTimeDT
FROM	bodb02.dbo.match14 AS t1 WITH (NOLOCK)
WHERE	t1.eventdate = @winlostdate;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 3: bingoBall_bk --------------------
	ELSE IF	@TableName = N'bingoBall_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.bingoBall_bk
	(	Matchid, Seq, Number, UpdateTime)
SELECT	Matchid, Seq, Number, UpdateTime
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	Matchid, Seq, Number, UpdateTime
FROM	bodb02.dbo.BingoBall14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 4: outright_bk --------------------
	ELSE IF	@TableName = N'outright_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.outright_bk
	(	orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR
	,	ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, autosuspend, EventID, Year)
SELECT	orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR
	,	ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, autosuspend, EventID, Year
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR
	,	ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, autosuspend, EventID, Year
FROM	bodb02.dbo.outright14 AS t1 WITH (NOLOCK)
WHERE	t1.eventdate = @winlostdate;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;

	---------------Table 5A: VSRaceInfo_bk --------------------
	ELSE IF	@TableName = N'VSRaceInfo_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.VSRaceInfo_bk
	(	[EventID], [EventTime], [LeagueID], [PayOut], [EachWay], [CourseName], [TrackType], [Distance], [Racers], [ForeCastPayout], [TriCastPayout], [CreateDate], [Calculate], [SportType], [ChangeTime], [EventStatus], [BetStatus])
SELECT	[EventID], [EventTime], [LeagueID], [PayOut], [EachWay], [CourseName], [TrackType], [Distance], [Racers], [ForeCastPayout], [TriCastPayout], [CreateDate], [Calculate], [SportType], [ChangeTime], [EventStatus], [BetStatus]
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	[EventID], [EventTime], [LeagueID], [PayOut], [EachWay], [CourseName], [TrackType], [Distance], [Racers], [ForeCastPayout], [TriCastPayout], [CreateDate], [Calculate], [SportType], [ChangeTime], [EventStatus], [BetStatus]
FROM	bodb02.dbo.VSRaceInfo14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.VSOutright14 o WITH(NOLOCK) WHERE t1.eventId = o.eventId AND o.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;

	---------------Table 5: VSOutright_bk --------------------
	ELSE IF	@TableName = N'VSOutright_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.VSOutright_bk
	(	Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, Lane, MaxBet, Placing, Creator, EventStatus)
SELECT	Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, Lane, MaxBet, Placing, Creator, EventStatus
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, Lane, MaxBet, Placing, Creator, EventStatus
FROM	bodb02.dbo.VSOutright14 AS t1 WITH (NOLOCK)
WHERE	t1.eventdate = @winlostdate;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 6: match_remark -----------------------------
	-- Need confirm: No sync column [SettlementStatus]?
	ELSE IF	@TableName = N'match_remark'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.match_remark
	(	matchid, calculate, multiple, calrefund, refund, calStatus, IsTotalBetDenied_1, IsTotalBetDenied_3, IsTotalBetDenied_7, IsTotalBetDenied_8, LiveTimer, HomeRedCard, AwayRedCard
	,	LivePeriod, HedgeForecast, IsTotalBetDenied_20, IsTotalBetDenied_21, IsNeutral, StreamingID, IsInternal, IsHTCal, LiveDeleteChecker, HomeColor, AwayColor, ConfirmHT, ConfirmFT
	,	PausePeriod, TimerSuspend, IsPending, isUndecided, StdDelBetCheck, HomeSubstitutes, AwaySubstitutes, StartTeam, HomePenalty, AwayPenalty, HomeYellowCard, AwayYellowCard
	,	Tier, OfferLive, CommGroup)
SELECT	matchid, calculate, multiple, calrefund, refund, calStatus, IsTotalBetDenied_1, IsTotalBetDenied_3, IsTotalBetDenied_7, IsTotalBetDenied_8, LiveTimer, HomeRedCard, AwayRedCard
	,	LivePeriod, HedgeForecast, IsTotalBetDenied_20, IsTotalBetDenied_21, IsNeutral, StreamingID, IsInternal, IsHTCal, LiveDeleteChecker, HomeColor, AwayColor, ConfirmHT, ConfirmFT
	,	PausePeriod, TimerSuspend, IsPending, isUndecided, StdDelBetCheck, HomeSubstitutes, AwaySubstitutes, StartTeam, HomePenalty, AwayPenalty, HomeYellowCard, AwayYellowCard
	,	Tier, OfferLive, CommGroup
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	matchid, calculate, multiple, calrefund, refund, calStatus, IsTotalBetDenied_1, IsTotalBetDenied_3, IsTotalBetDenied_7, IsTotalBetDenied_8, LiveTimer, HomeRedCard, AwayRedCard
	,	LivePeriod, HedgeForecast, IsTotalBetDenied_20, IsTotalBetDenied_21, IsNeutral, StreamingID, IsInternal, IsHTCal, LiveDeleteChecker, HomeColor, AwayColor, ConfirmHT, ConfirmFT
	,	PausePeriod, TimerSuspend, IsPending, isUndecided, StdDelBetCheck, HomeSubstitutes, AwaySubstitutes, StartTeam, HomePenalty, AwayPenalty, HomeYellowCard, AwayYellowCard
	,	Tier, OfferLive, CommGroup
FROM	bodb02.dbo.match_remark AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 7: MatchMaxbet_bk -----------------------------
	ELSE IF	@TableName = N'MatchMaxbet_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.MatchMaxbet_bk
	(	MatchId, BetType, Maxbet, OperatorId, Spread)
SELECT	MatchId, BetType, Maxbet, OperatorId, Spread
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MatchId, BetType, Maxbet, OperatorId, Spread
FROM	bodb02.dbo.matchMaxbet14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 8:  ResultDetail_bk -----------------------------
	ELSE IF	@TableName = N'ResultDetail_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.ResultDetail_bk
	(	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo)
SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	bodb02.dbo.ResultDetail14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 9:  ResultDetail3rd_bk -----------------------------
	ELSE IF	@TableName = N'ResultDetail3rd_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.ResultDetail3rd_bk
	(	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, Resourceid)
SELECT	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, Resourceid
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, Resourceid
FROM	bodb02.dbo.ResultDetail3rd14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 10:  EventInfo3rd_bk -----------------------------
	ELSE IF	@TableName = N'EventInfo3rd_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.EventInfo3rd_bk
	(	EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner)
SELECT	EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner
FROM	bodb02.dbo.EventInfo3rd14 AS t1 WITH (NOLOCK)
WHERE	t1.eventdate = @winlostdate;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 11:  AutoPayoutResult_bk -----------------------------
	ELSE IF	@TableName = N'AutoPayoutResult_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.AutoPayoutResult_bk
	(	AutoPayoutResultId, MatchId, CalculationType, SourceId, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate)
SELECT	AutoPayoutResultId, MatchId, CalculationType, SourceId, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	AutoPayoutResultId, MatchId, CalculationType, SourceId, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate
FROM	bodb02.dbo.AutoPayoutResult14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 12:  ProviderResultDetail_bk -----------------------------
	ELSE IF	@TableName = N'ProviderResultDetail_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.ProviderResultDetail_bk
	(	ProviderResultDetailId, MatchId, SourceId, TypeId, HomeValue, AwayValue, CreatedDate, IsConfirmed)
SELECT	ProviderResultDetailId, MatchId, SourceId, TypeId, HomeValue, AwayValue, CreatedDate, IsConfirmed
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ProviderResultDetailId, MatchId, SourceId, TypeId, HomeValue, AwayValue, CreatedDate, IsConfirmed
FROM	bodb02.dbo.ProviderResultDetail14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 13:  Odds3rd_bk -----------------------------
	ELSE IF	@TableName = N'Odds3rd_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.Odds3rd_bk
	(	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid)
SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
FROM	bodb02.dbo.Odds3rd14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 14:  Intg_OddsFeed_SettlementAction_bk -----------------------------
	ELSE IF	@TableName = N'Intg_OddsFeed_SettlementAction_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.Intg_OddsFeed_SettlementAction_bk
	(	ActionId, LeagueId, MatchId, ActionType, HTHomeScore, HTAwayScore, FTHomeScore, FTAwayScore, CreateTime, OtherInfo)
SELECT	ActionId, LeagueId, MatchId, ActionType, HTHomeScore, HTAwayScore, FTHomeScore, FTAwayScore, CreateTime, OtherInfo
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ActionId, LeagueId, MatchId, ActionType, HTHomeScore, HTAwayScore, FTHomeScore, FTAwayScore, CreateTime, OtherInfo
FROM	bodb02.dbo.Intg_OddsFeed_SettlementAction AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 15:  Intg_OddsFeed_SettlementAction_Outright_bk -----------------------------
	ELSE IF	@TableName = N'Intg_OddsFeed_SettlementAction_Outright_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.Intg_OddsFeed_SettlementAction_Outright_bk
	(	ActionId, ActionType, OrId, LeagueId, TeamId, Status, IsDeadheat, Deadheat, CreateTime)
SELECT	ActionId, ActionType, OrId, LeagueId, TeamId, Status, IsDeadheat, Deadheat, CreateTime
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ActionId, ActionType, OrId, LeagueId, TeamId, Status, IsDeadheat, Deadheat, CreateTime
FROM	bodb02.dbo.Intg_OddsFeed_SettlementAction_Outright AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.outright14 AS t2 WITH (NOLOCK) WHERE t1.orid = t2.orid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 16:  Match3rd_bk -----------------------------
	ELSE IF	@TableName = N'Match3rd_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.Match3rd_bk
	(	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, HasLive, EventStatus, VendorEventStatus, CreateTime, UpdateTime, VendorEventDate, GameResultDate)
SELECT	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, HasLive, EventStatus, VendorEventStatus, CreateTime, UpdateTime, VendorEventDate, GameResultDate
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, HasLive, EventStatus, VendorEventStatus, CreateTime, UpdateTime, VendorEventDate, GameResultDate
FROM	bodb02.dbo.Match3rd14 AS t1 WITH (NOLOCK)
WHERE	t1.eventdate = @winlostdate;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 17:  oddsES_bk -----------------------------
	ELSE IF	@TableName = N'oddsES_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.oddsES_bk
	(	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk
		, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category
		, IncreaseMaxbet, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
		, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
		, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
		, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
		, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
		, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
		, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
	)
SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk
	, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category
	, IncreaseMaxbet, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
	, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
	, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
	, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
	, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
	, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
	, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk
	, stakerange, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category
	, IncreaseMaxbet, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
	, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
	, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
	, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
	, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
	, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
	, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
FROM	bodb02.dbo.oddsES14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 18:  ResultDetailES_bk -----------------------------
	ELSE IF	@TableName = N'ResultDetailES_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO dbo.ResultDetailES_bk
	(	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo)
SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	bodb02.dbo.ResultDetailES14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 19:  SMP_Market_bk -----------------------------
	ELSE IF	@TableName = N'SMP_Market_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.SMP_Market_bk
	(	MarketId, MatchId, VendorId, Price, TradeStatus, Result, ResultStatusId, SelectionCounts, CreateTime, UpdateTime)
SELECT	MarketId, MatchId, VendorId, Price, TradeStatus, Result, ResultStatusId, SelectionCounts, CreateTime, UpdateTime
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MarketId, MatchId, VendorId, Price, TradeStatus, Result, ResultStatusId, SelectionCounts, CreateTime, UpdateTime
FROM	bodb02.dbo.SMP_Market14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 20:  SMP_MarketSelection_bk -----------------------------
	ELSE IF	@TableName = N'SMP_MarketSelection_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.SMP_MarketSelection_bk
	(	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId)
SELECT	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId
FROM	bodb02.dbo.SMP_MarketSelection14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 21:  Dot_Admin_Assignment_Trader_bk -----------------------------
	-- 20190925@Billy:	Add [Dot_Admin_Assignment_Trader] table
	ELSE IF	@TableName = N'Dot_Admin_Assignment_Trader_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.Dot_Admin_Assignment_Trader_bk
	(	ID, matchid, bettype, liveindicator, Detail_X, Detail_Y, Detail_Z, Type, TraderID, SuspenderID, UpdatedTime, UpdatedUser)
SELECT	ID, matchid, bettype, liveindicator, Detail_X, Detail_Y, Detail_Z, Type, TraderID, SuspenderID, UpdatedTime, UpdatedUser
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ID, matchid, bettype, liveindicator, Detail_X, Detail_Y, Detail_Z, Type, TraderID, SuspenderID, UpdatedTime, UpdatedUser
FROM	bodb02.dbo.Dot_Admin_Assignment_Trader AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 22:  oddsOS_bk -----------------------------
	-- 20190827@Billy:	Add [oddsOS] table
	ELSE IF	@TableName = N'oddsOS_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.oddsOS_bk
	(	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus
	,	liveindicator, changetime, risk, stakerange, newoffersetup, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, cs51, cs52, cs53, cs54, cs15, cs25, cs35, cs45, cs09, cs90
	,	cs99, comstatus, csstatus, commaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31
	,	bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, bal51, bal52, bal53, bal54, bal15
	,	bal25, bal35, bal45, bal09, bal90, bal99, maxbet, autoreject, autosuspend, multiple, stakerange2, risk2, isHedge, sporttype, HasBeenLinked, Resourceid
	,	maxPayout, EnableVirtualRate, Category, Sort, odds1aH, odds2aH, IsCopyDeadball, IsStatusIndep, ParentOddsId, TraderId)
SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus
	,	liveindicator, changetime, risk, stakerange, newoffersetup, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, cs51, cs52, cs53, cs54, cs15, cs25, cs35, cs45, cs09, cs90
	,	cs99, comstatus, csstatus, commaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31
	,	bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, bal51, bal52, bal53, bal54, bal15
	,	bal25, bal35, bal45, bal09, bal90, bal99, maxbet, autoreject, autosuspend, multiple, stakerange2, risk2, isHedge, sporttype, HasBeenLinked, Resourceid
	,	maxPayout, EnableVirtualRate, Category, Sort, odds1aH, odds2aH, IsCopyDeadball, IsStatusIndep, ParentOddsId, TraderId
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus
	,	liveindicator, changetime, risk, stakerange, newoffersetup, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
	,	cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, cs51, cs52, cs53, cs54, cs15, cs25, cs35, cs45, cs09, cs90
	,	cs99, comstatus, csstatus, commaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31
	,	bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, bal51, bal52, bal53, bal54, bal15
	,	bal25, bal35, bal45, bal09, bal90, bal99, maxbet, autoreject, autosuspend, multiple, stakerange2, risk2, isHedge, sporttype, HasBeenLinked, Resourceid
	,	maxPayout, EnableVirtualRate, Category, Sort, odds1aH, odds2aH, IsCopyDeadball, IsStatusIndep, ParentOddsId, TraderId
FROM	bodb02.dbo.oddsOS14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 23:  ResultDetailOS_bk -----------------------------
	-- 20190827@Billy:	Add [ResultDetailOS] table
	ELSE IF	@TableName = N'ResultDetailOS_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.ResultDetailOS_bk
	(	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo)
SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
FROM	bodb02.dbo.ResultDetailOS14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 24:  ProviderExternalResultDetailES_bk -----------------------------
	ELSE IF	@TableName = N'ProviderExternalResultDetailES_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.ProviderExternalResultDetailES_bk
	(	ProviderExternalId,MatchId3rd,MatchId,SourceId,ResourceId,HomeValue,AwayValue,OtherInfo,CreateDate,CreateBy,LastModifyDate,LastModifyBy)
SELECT	ProviderExternalId,MatchId3rd,MatchId,SourceId,ResourceId,HomeValue,AwayValue,OtherInfo,CreateDate,CreateBy,LastModifyDate,LastModifyBy
FROM	OPENQUERY(DBPRO, ''\
DECLARE	@winlostdate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @winlostdate, 121) + ''''';

SELECT	ProviderExternalId,MatchId3rd,MatchId,SourceId,ResourceId,HomeValue,AwayValue,OtherInfo,CreateDate,CreateBy,LastModifyDate,LastModifyBy
FROM	bodb02.dbo.ProviderExternalResultDetailES14 AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;

END

GO
/*<info serverAlias="DBARC-bodb_archive" executers="" viewers="" isFunction="0" isNested="1"></info>*/