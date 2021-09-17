SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_DailySummary_DB02_Copy]
						@winlostdate		DATETIME
AS
/*
-- Run on DB02 (ProductDB)
-- call by TransDB : Task_DailySummary

-- move match/odds/outright/bingoBall/SS_GameState/VSOutright into [14] table

	Database:	DBPRO.bodb02

	Revisions:
		-- 20110802@Sylvia: Insert Dot_Admin_Assignment_Operator to archive
		-- 20121014@Viet: add match.homeid2,match.awayid2
		-- 20121031@Sylvia: 1.add odds.Resourceid, odds.ResultKey
		--					2.add move SS_GameState table
		-- 20130520@Victor: add move data into VSOutright14 table
		-- 20140911@Lukas: add table MatchMaxbet14
		-- 20141006@Lukas: remove table SS_GameState14
		-- 20141024@Lukas: add table ResultDetail14
		-- 20141225@Jamie: Add OtherInfo into ResultDetail14
		-- 20150306@Cooper: Add MatchMaxbet.Spread into MatchMaxbet14
		-- 20150506@Victor(DB02): Add ParentID to Match14 and Match_BK
		-- 20150720@Sophia: Add ResultDetail3rd14 table
		-- 20151225@Sophia: Add EventInfo3rd14 table for Cockfighting 
		-- 20160302@Joychen: Add column  [cs99],[bal99] on odds For PH 
		-- 20160421@Sophia: Add AutoPayoutResult, ProviderResultDetail tables [Redmine: #49958]
		-- 20160715@Sylvia: add column autosuspend on outright/outright14
		-- 20161024@Patrick: Instant integration [Redmine: #66157]
					+ Add new identity field to AutoPayoutResult/AutoPayoutResult14 & ProviderResultDetail/ProviderResultDetail14
					+ Add new IsConfirmed field to ProviderResultDetail/ProviderResultDetail14
					+ Add new AutoSetting field to Match, Match14 & League
		-- 20170721@Billy: Add odds3rd table - [Redmine: #80382]
		-- 20171213@Sylvia: add columns EventID/Year on outright/outright14
		-- 20171220@Billy:	Add Match3rd table - [Redmine: #88506]
		-- 20180122@Billy:	Add [GameResultDate] column of [Match3rd] - [Redmine: #89833]
		-- 20180328@Billy:	Add [ResourceId] column of [ResultDetail3rd] - [Redmine: #91959]
		-- 20180405@Billy:	Add [cs04], [cs05], [ResourceId] columns of [Odds3rd] - [Redmine: #93175]
		-- 20180514@Patrick: Copy data from active to [14] batch by batch
		-- 20181204@Billy:	Add [oddsES] & [ResultDetailES] tables - [Redmine: #105816]
		-- 20190325@Billy:	Add [SMP_Market] & [SMP_MarketSelection] tables - [Redmine: #109926]
		-- 20190402@Billy:	Add [ShowTimeDT] of [match] - [Redmine: #109926]
		-- 20190717@Sylvia: Add match14 [ChildMatchType] column
		-- 20190827@Billy:	Add [oddsOS] & [ResultDetailOS] tables - [Redmine: #119257]
		-- 20200504@Patrick: Add more field for oddsES/oddsES14/oddsES_bk - [Redmine: #133538]
		-- 20200622@Patrick: Add more table VSRaceInfo [Redmine: #135963]
		-- 20200729@Brice:		Add table ProviderExternalResultDetailES [Redmine: #138380]
		-- 20200826@Brice:		Add table ProviderExternalResultDetailOS [Redmine: #139849]
		-- 20200909@Brice:		Add column color for table bingoBall [Redmine: #128414]
		-- 20201009@Brice:		Add columns GapOddsCap1,GapOddsCap2 for table odds [Redmine: #143211]
		-- 20201221@Brice:		Add table ProviderExternalResultDetail [Redmine: #145651]
		-- 20210122@Brice:		change 6 columns of [Match3rd] - [Redmine: #159842]
		-- 20210914@Patrick: Support bitcoin project: Odds3rd & ResultDetail3rd [Redmine: #159842]
*/

BEGIN
SET NOCOUNT ON

	declare @rowId int, @rowInBatch int
	create table #__matchIdList (rowId int identity(1,1), matchid int)
	insert into #__matchIdList(matchid)
	select matchid
	from dbo.match where eventdate = @winlostdate

	--get data from Match3rd
	create table #__match3rdIdList (rowId int identity(1,1), match3rdId int)
	insert into #__match3rdIdList(match3rdId)
	select Match3rdId
	from dbo.Match3rd where eventdate = @winlostdate
	
	create table #__IdsList (rowId int identity(1,1) primary key, Id int)
	create table #__tempData (id int)

	select @rowId = 0, @rowInBatch = 3000
	insert into #__IdsList(Id)
	select oddsid
	from dbo.odds with(nolock)
	where matchid in (select matchid from #__matchIdList)
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch
		
		insert into odds14
			([oddsid], [matchid], [bettype], [switch], [hdp1], [hdp2],
			 [odds1a], [odds2a], [odds1b], [odds2b], [odds1c], [odds2c], [odds1e], 
			 [odds2e], [odds1f], [odds2f], [odds1d], [odds2d], [odds1hka], [odds2hka],
			 [odds1hkb], [odds2hkb], [odds1hkc], [odds2hkc], [odds1hke], [odds2hke], [odds1hkf],
			 [odds2hkf], [odds1hkd], [odds2hkd], [oddsspreada], [oddsspreadb], [oddsspreadd], 
			 [oddsspreade], [oddsspreadf], [oddsspreadc], [autobookie], [gapodds1], [gapodds2],
			 [maxstake1], [maxstake2], [minstake1], [minstake2], [diffbalance], [maxodds], 
			 [minodds], [oddsstatus], [liveindicator], [changetime], [risk], [stakerange],
			 [newoffersetup], [livehomescore], [liveawayscore], [creator], [com1], [comx],
			 [com2], [cs00], [cs01], [cs10], [cs11], [cs02], [cs12], [cs22], [cs21], [cs20],
			 [cs30], [cs31], [cs32], [cs33], [cs23], [cs13], [cs03], [cs43], [cs42], [cs41],
			 [cs40], [cs44], [cs14], [cs24], [cs04], [cs34], [cs50], [cs05], [comstatus], 
			 [csstatus], [commaxbet], [csmaxbet], [com1total], [comxtotal], [com2total],
			 [bal00], [bal10], [bal11], [bal01], [bal20], [bal21], [bal22], [bal12], 
			 [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], 
			 [bal40], [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14],
			 [bal04], [bal50], [bal05], [maxbet], [multiple], [allowance], [risk2], 
			 [stakerange2], [allowance2], [hometotal], [awaytotal], sporttype, Resourceid, ResultKey,GapOddsCap1,GapOddsCap2,
			 [cs99],[bal99])
		select
			[oddsid], [matchid], [bettype], [switch], [hdp1], [hdp2],
			[odds1a], [odds2a], [odds1b], [odds2b], [odds1c], [odds2c], [odds1e], 
			[odds2e], [odds1f], [odds2f], [odds1d], [odds2d], [odds1hka], [odds2hka],
			[odds1hkb], [odds2hkb], [odds1hkc], [odds2hkc], [odds1hke], [odds2hke], [odds1hkf],
			[odds2hkf], [odds1hkd], [odds2hkd], [oddsspreada], [oddsspreadb], [oddsspreadd], 
			[oddsspreade], [oddsspreadf], [oddsspreadc], [autobookie], [gapodds1], [gapodds2],
			[maxstake1], [maxstake2], [minstake1], [minstake2], [diffbalance], [maxodds], 
			[minodds], [oddsstatus], [liveindicator], [changetime], [risk], [stakerange],
			[newoffersetup], [livehomescore], [liveawayscore], [creator], [com1], [comx],
			[com2], [cs00], [cs01], [cs10], [cs11], [cs02], [cs12], [cs22], [cs21], [cs20],
			[cs30], [cs31], [cs32], [cs33], [cs23], [cs13], [cs03], [cs43], [cs42], [cs41],
			[cs40], [cs44], [cs14], [cs24], [cs04], [cs34], [cs50], [cs05], [comstatus], 
			[csstatus], [commaxbet], [csmaxbet], [com1total], [comxtotal], [com2total],
			[bal00], [bal10], [bal11], [bal01], [bal20], [bal21], [bal22], [bal12], 
			[bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], 
			[bal40], [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14],
			[bal04], [bal50], [bal05], [maxbet], [multiple], [allowance], [risk2], 
			[stakerange2], [allowance2], [hometotal], [awaytotal], sporttype, Resourceid, ResultKey,GapOddsCap1,GapOddsCap2,
			[cs99],[bal99]
		from odds o with(nolock)
		where o.oddsid in (select id from #__tempData)

		waitfor delay '00:00:01'
	end
-------------------20200729@Brice:		Add table ProviderExternalResultDetailES [Redmine: #138380]-----------------------------------------------------------------------------
	truncate table #__IdsList
	select @rowId = 0
	insert into #__IdsList(Id)
	select p.ProviderExternalId
	from dbo.ProviderExternalResultDetailES p with(nolock)
	where matchid in (select matchid from #__matchIdList)
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		insert into dbo.ProviderExternalResultDetailES14([ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy])
		select [ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy]
		from dbo.ProviderExternalResultDetailES with(nolock)
		where ProviderExternalId in (select id from #__tempData)

		waitfor delay '00:00:01'
	end
------------------/20200729@Brice:		Add table ProviderExternalResultDetailES [Redmine: #138380]-----------------------------------------------------------------------------
-------------------20200826@Brice:		Add table ProviderExternalResultDetailOS [Redmine: #139849]-----------------------------------------------------------------------------
	truncate table #__IdsList
	select @rowId = 0
	insert into #__IdsList(Id)
	select p.ProviderExternalId
	from dbo.ProviderExternalResultDetailOS p with(nolock)
	where matchid in (select matchid from #__matchIdList)
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		insert into dbo.ProviderExternalResultDetailOS14([ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy])
		select [ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy]
		from dbo.ProviderExternalResultDetailOS with(nolock)
		where ProviderExternalId in (select id from #__tempData)

		waitfor delay '00:00:01'
	end
------------------/20200826@Brice:		Add table ProviderExternalResultDetailOS [Redmine: #139849]-----------------------------------------------------------------------------

-------------------20201221@Brice:		Add table ProviderExternalResultDetail [Redmine: #145651]-----------------------------------------------------------------------------
	truncate table #__IdsList
	select @rowId = 0
	insert into #__IdsList(Id)
	select p.ProviderExternalId
	from dbo.ProviderExternalResultDetail p with(nolock)
	where matchid in (select matchid from #__matchIdList)
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		insert into dbo.ProviderExternalResultDetail14([ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy])
		select [ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[CreateBy],[LastModifyDate],[LastModifyBy]
		from dbo.ProviderExternalResultDetail with(nolock)
		where ProviderExternalId in (select id from #__tempData)

		waitfor delay '00:00:01'
	end
------------------/20201221@Brice:		Add table ProviderExternalResultDetail [Redmine: #145651]-----------------------------------------------------------------------------

	SELECT	@rowId = 0;
	WHILE	1 = 1
	BEGIN
		TRUNCATE TABLE #__tempData;

		INSERT INTO #__tempData (id)
		SELECT	matchid
		FROM	#__matchIdList
		WHERE	rowId > @rowId
			AND	rowId <= @rowId + @rowInBatch;

		IF	@@ROWCOUNT = 0
			BREAK;

		SET	@rowId = @rowId + @rowInBatch;

		INSERT INTO	dbo.match14 (
				matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode
			,	kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp, homeid2, awayid2, DisplayMode
			,	LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime, GlobalShowTime, ParentID, IsAutoPayout, AutoSetting, ShowTimeDT, ChildMatchType
			)
		SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode
			,	kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, tstamp, homeid2, awayid2, DisplayMode
			,	LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime, GlobalShowTime, ParentID, IsAutoPayout, AutoSetting, ShowTimeDT, ChildMatchType
		FROM	dbo.match WITH (NOLOCK)
		WHERE	matchid IN (SELECT id FROM #__tempData);

		WAITFOR DELAY '00:00:01';
	END;

	INSERT INTO bingoBall14
		([Matchid], [Seq], [Number], [UpdateTime], [Color])
	SELECT
		[Matchid], [Seq], [Number], [UpdateTime], [Color]
	FROM BingoBall
	WHERE MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	waitfor delay '00:00:01'

	insert into outright14
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds,
		matchcode, groupmatch, status, creator,	bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR,
		ProgramID, FOddsstatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck,autosuspend,
		EventID, Year)
	select
		orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds,
		matchcode, groupmatch, status, creator,	bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR,
		ProgramID, FOddsstatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck,autosuspend,
		EventID, Year
	from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'

	waitfor delay '00:00:01'

	--VSRaceInfo
	truncate table #__IdsList
	select @rowId = 0
	insert into #__IdsList(Id)
	select r.EventId
	from dbo.VSRaceInfo r with(nolock)
	where exists (
		select top 1 1
		from dbo.VSOutright o with(nolock)
		where o.eventdate = @winlostdate and o.EventStatus = 'Completed' and r.EventId = o.EventId
	)
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		insert into dbo.VSRaceInfo14([EventID], [EventTime], [LeagueID], [PayOut], [EachWay], [CourseName], [TrackType], [Distance], [Racers], [ForeCastPayout], [TriCastPayout], [CreateDate], [Calculate], [SportType], [ChangeTime], [EventStatus], [BetStatus])
		select [EventID], [EventTime], [LeagueID], [PayOut], [EachWay], [CourseName], [TrackType], [Distance], [Racers], [ForeCastPayout], [TriCastPayout], [CreateDate], [Calculate], [SportType], [ChangeTime], [EventStatus], [BetStatus]
		from dbo.VSRaceInfo with(nolock)
		where EventId in (select id from #__tempData)

		waitfor delay '00:00:01'
	end

	waitfor delay '00:00:01'

	truncate table #__IdsList
	select @rowId = 0
	insert into #__IdsList(Id)
	select Orid
	from dbo.VSOutright with(nolock)
	where eventdate = @winlostdate AND EventStatus = 'Completed'
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		insert into VSOutright14
			(Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, 
			Lane, MaxBet, Placing, Creator, EventStatus)
		select 	
			Orid, EventID, RacerNum, IsFavor, EventDate, KickoffTime, RacerID, HumanID, WinOdds, PlaceOdds, 
			Lane, MaxBet, Placing, Creator, EventStatus
		from VSOutright with(nolock)
		where Orid in (select id from #__tempData)

		waitfor delay '00:00:01'
	end

	--INSERT INTO SS_GameState14
	--	(Matchid, ResultKey, ResultValue, SortKey)
	--SELECT
	--	Matchid, ResultKey, ResultValue, SortKey
	--FROM SS_GameState
	--WHERE MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	INSERT INTO DB06.bodb_archive.dbo.Dot_Admin_Assignment_Operator_bk
		(ID, matchid, OperatorType, OperatorID, bettype)
	SELECT 
		ID, matchid, OperatorType, OperatorID, bettype
	FROM Dot_Admin_Assignment_Operator
	WHERE MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)
	
	waitfor delay '00:00:01'

	INSERT INTO MatchMaxbet14(MatchId, BetType, Maxbet, OperatorId, Spread )
	SELECT MatchId, BetType, Maxbet, OperatorId, Spread 
	FROM MatchMaxbet WITH(NOLOCK)
	WHERE matchid IN (SELECT MatchID from Match where eventdate = @winlostdate)	
	
	waitfor delay '00:00:01'

	select @rowId = 0
	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select matchid from #__matchIdList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		INSERT INTO	dbo.ResultDetail14
			(	MatchId, ResourceId, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateDate, LastModifyDate, CreateBy, LastModifyBy, OtherInfo)
		SELECT	MatchId, ResourceId, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateDate, LastModifyDate, CreateBy, LastModifyBy, OtherInfo
		FROM	dbo.ResultDetail WITH (NOLOCK)
		WHERE	MatchId IN (SELECT id FROM #__tempData)

		waitfor delay '00:00:01'
	end

	--ResultDetail3rd@match&match3rd
	truncate table #__IdsList
	select @rowId = 0

	insert into #__IdsList(Id)
	select ResultID
	from dbo.ResultDetail3rd with(nolock)
	where matchid in (select t.matchid from #__matchIdList t)
	union
	select ResultID
	from dbo.ResultDetail3rd with(nolock)
	where matchid in (select t.match3rdId from #__match3rdIdList t)

	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		-- 20180328@Billy -- Add column [ResourceId]
		INSERT INTO	dbo.ResultDetail3rd14
			(	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId)
		SELECT	ResultID, VendorID, MatchID, GameID, Custom1, Custom2, Custom3, ResultStatusID, SettlementStatusID, GameResult, OtherInfo, CreateBy, CreateDate, LastModifyBy, LastModifyDate, ResourceId
		FROM	dbo.ResultDetail3rd WITH (NOLOCK)
		WHERE	ResultID IN (SELECT id from #__tempData)

		waitfor delay '00:00:01'
	end

	INSERT INTO dbo.EventInfo3rd14 (EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner)
	SELECT	EventInfo3rdID, ArenaID, FightNo, EventDate, HomeOwner, AwayOwner
	FROM	dbo.EventInfo3rd WITH (NOLOCK)
	WHERE	EventDate = @winlostdate

	waitfor delay '00:00:01'

	INSERT INTO AutoPayoutResult14 (AutoPayoutResultId, MatchId, CalculationType, SourceId, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate)
	SELECT	AutoPayoutResultId, MatchId, CalculationType, SourceId, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate
	FROM	dbo.AutoPayoutResult WITH (NOLOCK)
	WHERE	Matchid IN (SELECT MatchID from dbo.Match where eventdate = @winlostdate)	

	waitfor delay '00:00:01'

	INSERT INTO ProviderResultDetail14 (ProviderResultDetailId, MatchId, SourceId, TypeId, HomeValue, AwayValue, CreatedDate, IsConfirmed)
	SELECT	ProviderResultDetailId, MatchId, SourceId, TypeId, HomeValue, AwayValue, CreatedDate, IsConfirmed
	FROM	dbo.ProviderResultDetail WITH (NOLOCK)
	WHERE	Matchid IN (SELECT MatchID from dbo.Match where eventdate = @winlostdate)	

	waitfor delay '00:00:01'

	truncate table #__IdsList
	select @rowId = 0

	insert into #__IdsList(Id)
	select oddsid
	from dbo.Odds3rd with(nolock)
	where matchid in (select t.matchid from #__matchIdList t)
	union
	select oddsid
	from dbo.Odds3rd with(nolock)
	where matchid in (select t.match3rdId from #__match3rdIdList t)

	while 1 = 1
	begin
		truncate table #__tempData

		insert into #__tempData(id)
		select id from #__IdsList where rowId > @rowId and rowId <= @rowId + @rowInBatch
		if @@rowcount = 0
			break

		set @rowId = @rowId + @rowInBatch

		-- Odds3rd: [tstamp] and [ExtraInfo] are EXCLUDED
		-- 20180405@Billy -- Add columns [cs04], [cs05], [ResourceId]
		INSERT INTO	dbo.Odds3rd14
			(	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid)
		SELECT	oddsid, matchid, odds3rdid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, changetime, creator, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs99, sporttype, cs04, cs05, Resourceid
		FROM	dbo.Odds3rd WITH (NOLOCK)
		WHERE	oddsid IN (SELECT id from #__tempData)
		
		waitfor delay '00:00:01'
	end

	-- 20171220@Billy -- New table [Match3rd_bk]
	-- 20180122@Billy -- Add column [GameResultDate]
	INSERT INTO	dbo.Match3rd14
		(	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, EventStatus, CreateTime, UpdateTime, StartTime, MarketEndTime, EndTime, BetStatus)
	SELECT	Match3rdId, League3rdId, HomeId, AwayId, EventDate, SportType, VendorMatchId, MatchNo, EventStatus, CreateTime, UpdateTime, StartTime, MarketEndTime, EndTime, BetStatus
	FROM	dbo.Match3rd WITH (NOLOCK)
	WHERE	EventDate = @winlostdate;

	-- 20181204@Billy -- New table [oddsES]
	INSERT INTO	dbo.oddsES14
		(	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange
			, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category, IncreaseMaxbet
			, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
			, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
			, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
			, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
			, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
			, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
			, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
		)
	SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange
		, newoffersetup, livehomescore, liveawayscore, creator, com1, com2, csstatus, maxbet, autosuspend, stakerange2, risk2, site3, sporttype, HasBeenLinked, Resourceid, Category, IncreaseMaxbet
		, odds1aH, odds2aH, IsCopyDeadball, GoalLineDiff, IsStatusIndep, ParentOddsId, RefOddsSP, RefOddsH, RefOddsA, RefTrueOdds, CurrentTrueOdds, EnableVirtualRate, TraderId
		, [cs00], [cs01], [cs10],[cs11], [cs02], [cs12], [cs22], [cs21], [cs20], [cs30], [cs31], [cs32], [cs33], [cs23]
		, [cs13], [cs03], [cs43], [cs42], [cs41], [cs40], [cs44], [cs14], [cs24], [cs04], [cs34],[cs50], [cs05], [cs51]
		, [cs52], [cs53], [cs54], [cs15], [cs25], [cs35], [cs45], [cs09], [cs90], [cs99], [bal00], [bal10], [bal11], [bal01]
		, [bal20], [bal21], [bal22], [bal12], [bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], [bal40]
		, [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14], [bal04], [bal50], [bal05], [bal51], [bal52], [bal53]
		, [bal54], [bal15], [bal25], [bal35], [bal45], [bal09], [bal90], [bal99]
	FROM	dbo.oddsES AS oes WITH (NOLOCK)
	WHERE	EXISTS(SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = oes.matchid AND m.eventdate = @winlostdate);

	-- 20181204@Billy -- New table [ResultDetailES]
	INSERT INTO	dbo.ResultDetailES14
		(	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo)
	SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
	FROM	dbo.ResultDetailES AS rdes WITH (NOLOCK)
	WHERE	EXISTS(SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = rdes.matchid AND m.eventdate = @winlostdate);

	-- 20190325@Billy -- New table [SMP_Market]
	INSERT INTO	dbo.SMP_Market14
		(	MarketId, MatchId, VendorId, Price, TradeStatus, Result, ResultStatusId, SelectionCounts, CreateTime, UpdateTime)
	SELECT	MarketId, MatchId, VendorId, Price, TradeStatus, Result, ResultStatusId, SelectionCounts, CreateTime, UpdateTime
	FROM	dbo.SMP_Market AS sm WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = sm.MatchId AND m.eventdate = @winlostdate);

	-- 20190325@Billy -- New table [SMP_MarketSelection]
	INSERT INTO	dbo.SMP_MarketSelection14
		(	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId)
	SELECT	MarketSelectionId, MarketId, SelectionType, Result, ResultStatusId, MatchId
	FROM	dbo.SMP_MarketSelection AS sms WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = sms.MatchId AND m.eventdate = @winlostdate);

	-- 20190827@Billy -- New table [oddsOS]
	INSERT INTO	dbo.oddsOS14
		(	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus
		,	liveindicator, changetime, risk, stakerange, newoffersetup, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
		,	cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, cs51, cs52, cs53, cs54, cs15, cs25, cs35, cs45, cs09, cs90
		,	cs99, comstatus, csstatus, commaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31
		,	bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, bal51, bal52, bal53, bal54, bal15
		,	bal25, bal35, bal45, bal09, bal90, bal99, maxbet, autoreject, autosuspend, multiple, stakerange2, risk2, isHedge, sporttype, HasBeenLinked, Resourceid
		,	maxPayout, EnableVirtualRate, Category, Sort, odds1aH, odds2aH, IsCopyDeadball, IsStatusIndep, ParentOddsId, TraderId
		)
	SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, oddsspreada, autobookie, gapodds1, gapodds2, diffbalance, maxodds, minodds, oddsstatus
		,	liveindicator, changetime, risk, stakerange, newoffersetup, com1, comx, com2, cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32
		,	cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, cs51, cs52, cs53, cs54, cs15, cs25, cs35, cs45, cs09, cs90
		,	cs99, comstatus, csstatus, commaxbet, com1total, comxtotal, com2total, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31
		,	bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, bal51, bal52, bal53, bal54, bal15
		,	bal25, bal35, bal45, bal09, bal90, bal99, maxbet, autoreject, autosuspend, multiple, stakerange2, risk2, isHedge, sporttype, HasBeenLinked, Resourceid
		,	maxPayout, EnableVirtualRate, Category, Sort, odds1aH, odds2aH, IsCopyDeadball, IsStatusIndep, ParentOddsId, TraderId
	FROM	dbo.oddsOS AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = tbl.MatchId AND m.eventdate = @winlostdate);

	-- 20190827@Billy -- New table [ResultDetailOS]
	INSERT INTO	dbo.ResultDetailOS14
		(	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo)
	SELECT	MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate, OtherInfo
	FROM	dbo.ResultDetailOS AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE m.matchid = tbl.MatchId AND m.eventdate = @winlostdate);

	drop table #__tempData
	drop table #__IdsList
	drop table #__matchIdList
	drop table #__match3rdIdList

END
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/