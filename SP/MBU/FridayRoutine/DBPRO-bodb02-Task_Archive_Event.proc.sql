SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Event
						@winlostdate	DATETIME
					,	@Action			VARCHAR(10)		= NULL -- copy / delete / subtask	
					,	@DeletedTarget	VARCHAR(100)	= ''
AS
/*
	Database:	DBPRO.bodb02
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
		- 20160401@Sophia: Add Column Matchmaxbet.Spread [Redmind: #55115]
		- 20160421@Sophia: Add AutoPayoutResult, ProviderResultDetail tables [Redmine: #49958]
		- 20160715@Sylvia: Add column autosuspend into outright_bk
		- 20161007@Viet: Add parameter @action, to separate copy and delete process.
		- 20161024@Patrick: + Add new identity field for AutoPayoutResult_bk & ProviderResultDetail_bk [Redmine: #66157]
							+ Add new IsConfirmed field to ProviderResultDetail_bk
		- 20170721@Billy:	Add odds3rd table - [Redmine: #80382]
		- 20171012@Lukas: put event14 table into execRep SP to reduce workload on DBDIST02
		- 20171031@Lukas: add 2 tables Intg_OddsFeed_SettlementAction & Intg_OddsFeed_SettlementAction_Outright
		- 20171213@Sylvia: Add column EventID/Year in outright_bk
		- 20171221@Billy:	Add Match3rd table - [Redmine: #88506]
		- 20180122@Billy:	Add [GameResultDate] column of [Match3rd] - [Redmine: #89833]
		- 20180328@Billy:	Add [ResourceId] column of [ResultDetail3rd] - [Redmine: #91959]
		- 20180405@Billy:	Add [cs04], [cs05], [ResourceId] columns of [Odds3rd] - [Redmine: #93175]
		- 20181204@Billy:	Add [oddsES] & [ResultDetailES] tables - [Redmine: #105816]
							Add column list to [odds] table - [Redmine: #000000]
		- 20181214@Billy:	Fix duplicate PK in #DeletedList - [Redmine: #106358]
		- 20181219@Billy:	Add [Tier] column of [match_remark] - [Redmine: #106648]
		- 20190325@Billy:	Add [SMP_Market] & [SMP_MarketSelection] tables - [Redmine: #109926]
		- 20190925@Billy:	Remove @Action = 'copy' - Using Task_Archive_Event_Control for copying instead
							Add [Dot_Admin_Assignment_Trader] table - [Redmine: #117014]
		- 20190911@Billy:	Add [oddsES] & [ResultDetailES] tables - [Redmine: #119257]
*/
BEGIN
	SET NOCOUNT ON;

	IF @Action = 'delete'
	BEGIN
		DELETE FROM dbo.Intg_OddsFeed_SettlementAction 
		WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate);

		DELETE FROM dbo.Intg_OddsFeed_SettlementAction_Outright 
		WHERE orid IN (SELECT orid FROM outright14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		--- delete match_remark base on match14
		DELETE FROM dbo.match_Remark WHERE matchid in (select matchid from dbo.match14 where eventdate = @winlostdate)
		WAITFOR DELAY '00:00:01'


		CREATE TABLE #DeletedList (id INT PRIMARY KEY CLUSTERED,IsDone BIT)

		---### delete data for odds14
		INSERT INTO #DeletedList (id,IsDone)
		SELECT oddsid,0 
		FROM dbo.odds14  WHERE matchid IN (SELECT matchid FROM dbo.match14 WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on odds14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'odds14'

		---### delete data for BingoBall14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT DISTINCT Matchid,0 
		FROM dbo.BingoBall14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on BingoBall14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'BingoBall14'

		---### delete data for matchMaxbet14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT DISTINCT Matchid,0 
		FROM dbo.matchMaxbet14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on matchMaxbet14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'matchMaxbet14'

		---### delete data for ResultDetail14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT DISTINCT Matchid,0 
		FROM dbo.ResultDetail14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on matchMaxbet14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'ResultDetail14'

		---### delete data for ResultDetail3rd14  ###---
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT ResultID,0 
		FROM dbo.ResultDetail3rd14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on ResultDetail3rd14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'ResultDetail3rd14'

		---### delete data for AutoPayoutResult14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT DISTINCT matchid,0 
		FROM dbo.AutoPayoutResult14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on AutoPayoutResult14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'AutoPayoutResult14'
		
		---### delete data for ProviderResultDetail14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT DISTINCT matchid,0 
		FROM dbo.ProviderResultDetail14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on ProviderResultDetail14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'ProviderResultDetail14'

		---### delete data for Odds3rd14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT oddsID,0 
		FROM dbo.Odds3rd14 WITH(NOLOCK) WHERE matchid IN (SELECT matchid FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate)

		-- call subtask for looping & deleting data on Odds3rd14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'Odds3rd14'


		---### delete data for outright14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT orid,0 
		FROM dbo.outright14 WITH(NOLOCK) WHERE eventdate = @winlostdate 

		-- call subtask for looping & deleting data on outright14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'outright14'

		---### delete data for VSOutright14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT orid,0 
		FROM dbo.VSOutright14 WITH(NOLOCK) WHERE eventdate = @winlostdate 

		-- call subtask for looping & deleting data on VSOutright14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'VSOutright14'

		---### delete data for EventInfo3rd14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT EventInfo3rdID,0 
		FROM dbo.EventInfo3rd14 WITH(NOLOCK) WHERE eventdate = @winlostdate 

		-- call subtask for looping & deleting data on EventInfo3rd14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'EventInfo3rd14'


		---### Delete data for Match3rd14
			-- 20171221@Billy -- New table Match3rd14
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	Match3rdId, 0
		FROM	dbo.Match3rd14 WITH (NOLOCK)
		WHERE	eventdate = @winlostdate;

		-- Call subtask for looping & deleting data on Match3rd14
			-- 20171221@Billy -- New table Match3rd14
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'Match3rd14';


		---### Delete data for oddsES14
			-- 20181204@Billy -- New table oddsES14
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	oes.oddsid, 0
		FROM	dbo.oddsES14 AS oes WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE oes.matchid = m.matchid AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on oddsES14
			-- 20181204@Billy -- New table oddsES14
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'oddsES14';


		---### Delete data for ResultDetailES14
			-- 20181204@Billy -- New table ResultDetailES14
			-- 20181214@Billy -- Fix duplicate PK in #DeletedList
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	DISTINCT
				rdes.MatchID, 0
		FROM	dbo.ResultDetailES14 AS rdes WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE rdes.matchid = m.matchid AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on ResultDetailES14
			-- 20181204@Billy -- New table ResultDetailES14
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'ResultDetailES14';


		---### Delete data for [SMP_Market14]
			-- 20190325@Billy -- New table [SMP_Market14]
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	DISTINCT
				sm.MatchId, 0
		FROM	dbo.SMP_Market14 AS sm WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.matchid = sm.MatchId AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on [SMP_Market14]
			-- 20190325@Billy -- New table [SMP_Market14]
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'SMP_Market14';


		---### Delete data for [SMP_MarketSelection14]
			-- 20190325@Billy -- New table [SMP_MarketSelection14]
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	sms.MarketSelectionId, 0
		FROM	dbo.SMP_MarketSelection14 AS sms WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.matchid = sms.MatchId AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on [SMP_MarketSelection14]
			-- 20190325@Billy -- New table [SMP_MarketSelection14]
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'SMP_MarketSelection14';


		---### Delete data for [Dot_Admin_Assignment_Trader]
			-- 20190925@Billy -- New table [Dot_Admin_Assignment_Trader]
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	daat.ID, 0
		FROM	dbo.Dot_Admin_Assignment_Trader AS daat WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.matchid = daat.MatchId AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on [Dot_Admin_Assignment_Trader]
			-- 20190925@Billy -- New table [Dot_Admin_Assignment_Trader]
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'Dot_Admin_Assignment_Trader';


		---### Delete data for oddsOS14
			-- 20190911@Billy -- New table oddsOS14
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	tbl.oddsid, 0
		FROM	dbo.oddsOS14 AS tbl WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on oddsOS14
			-- 20190911@Billy -- New table oddsOS14
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'oddsOS14';


		---### Delete data for ResultDetailOS14
			-- 20190911@Billy -- New table ResultDetailOS14
		TRUNCATE TABLE	#DeletedList;
		INSERT INTO	#DeletedList (id, IsDone)
		SELECT	DISTINCT
				tbl.MatchID, 0
		FROM	dbo.ResultDetailOS14 AS tbl WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @winlostdate);

		-- Call subtask for looping & deleting data on ResultDetailOS14
			-- 20190911@Billy -- New table ResultDetailOS14
		EXECUTE	dbo.Task_Archive_Event @winlostdate = @winlostdate, @Action = 'subtask', @DeletedTarget = 'ResultDetailOS14';


		---### delete data for match14
		TRUNCATE TABLE #DeletedList
		INSERT INTO #DeletedList (id,IsDone)
		SELECT matchid,0 
		FROM dbo.match14 WITH(NOLOCK) WHERE eventdate = @winlostdate

		-- call subtask for looping & deleting data on match14
		EXEC [dbo].[Task_Archive_Event] @winlostdate = @winlostdate ,@Action = 'subtask', @DeletedTarget = 'match14'

		-- Extra Cleanup for Match_Remark
		IF DATEPART(dw, @winlostdate) = 5
		BEGIN
			-- get list
			SELECT matchid AS mid INTO #m FROM match_remark

			-- remove matchid which is current, only data left is good to remove
			DELETE #m FROM dbo.match m   WHERE #m.mid = m.matchid
			DELETE #m FROM dbo.match14 m WHERE #m.mid = m.matchid

			-- remove it
			DELETE match_Remark FROM #m WHERE match_remark.matchid = #m.mid
		END
	END -- end @action = 'delete'
	IF @Action = 'subtask'
	BEGIN
		DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topn INT = 1000
		CREATE TABLE #output (id INT)	

		SET @rowcount = 1
		WHILE @rowcount <> 0
		BEGIN
			TRUNCATE TABLE #output
			SET @ids = NULL

			DELETE TOP(@topn) t
			OUTPUT deleted.id INTO #output(id)
			FROM #DeletedList t
			SET @rowcount = @@ROWCOUNT

			SELECT @ids = COALESCE(@ids + '^' + CAST(id AS VARCHAR(50)), CAST(id AS VARCHAR(50)))
			FROM #output  

			EXEC [dbo].[ExecRep_APL_03] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
		END
		DROP TABLE #output
	END
END
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/