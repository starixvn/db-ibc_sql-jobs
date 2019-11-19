SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[ExecRep_APL_01]
	@Winlostdate DATETIME
AS
/*
	Created by:	Sophia
	Date:		20130831
	Task:		Called by Task_DailySummary_DB02_Delete
				Delete Event by WinlostDate		
	Database:	DBPRO.bodb02
	Revisions:
		- 20130809@viet: revise SP, then add to DB02_odds_info publication.
		- 20140911@Lukas: add table MatchMaxbet 
		- 20141006@Lukas: remove table SS_GameState
		- 20141024@Lukas: add table ResultDetail
		- 20150727@Sophia: add table ResultDetail3rd
		- 20150105@Sophia: add table EventInfo3rd
		- 20160421@Sophia: Add AutoPayoutResult, ProviderResultDetail tables [Redmine: #49958]
		- 20170721@Billy:	Add odds3rd table - [Redmine: #80382]
		- 20171221@Billy:	Add Match3rd table - [Redmine: #88506]
		- 20181204@Billy:	Add [oddsES] & [ResultDetailES] tables - [Redmine: #105816]
		- 20190325@Billy:	Add [SMP_Market] & [SMP_MarketSelection] tables - [Redmine: #109926]
		- 20190828@Billy:	Add [oddsOS] & [ResultDetailOS] tables - [Redmine: #119257]
*/ 
BEGIN

	SET NOCOUNT ON 
	IF @@SERVERNAME = 'DBCLS1\SDBPROD' RETURN --- ProdDB of Apollo
		

	IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'match' AND type = 'U') RETURN -- no match table, do nothing

	-- delete odds			
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'odds' AND type = 'U')
	BEGIN
		delete from odds
		where matchid in (select matchid from match where eventdate=@winlostdate)
	END

	-- delete bingoball
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'BingoBall' AND type = 'U')
	BEGIN
		delete from BingoBall
		where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)
	END

	--delete Dot_Admin_Assignment_Operator
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Dot_Admin_Assignment_Operator' AND type = 'U')
	BEGIN
		delete from Dot_Admin_Assignment_Operator 
		where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

		IF DATEPART(weekday, @winlostdate) = 2
		BEGIN
			delete from Dot_Admin_Assignment_Operator 
			where MatchID not in (SELECT MatchID from Match with(nolock))
		END
	END

	-- delete SS_GameState
	--IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SS_GameState' AND type = 'U')
	--BEGIN
	--	delete from SS_GameState
	--	where matchid in (select matchid from match where eventdate=@winlostdate)
	--END

	-- delete MatchMaxbet
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'MatchMaxbet' AND type = 'U')
	BEGIN
		delete from MatchMaxbet WITH(ROWLOCK)
		where matchid in (select matchid from match WITH(NOLOCK) where eventdate=@winlostdate)
	END

	-- delete ResultDetail
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ResultDetail' AND type = 'U')
	BEGIN
		delete from ResultDetail WITH(ROWLOCK)
		where matchid in (select matchid from match WITH(NOLOCK) where eventdate=@winlostdate)
	END

	-- delete ResultDetail
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ResultDetail3rd' AND type = 'U')
	BEGIN
		DELETE FROM ResultDetail3rd WITH(ROWLOCK)
		WHERE matchid in (SELECT matchid FROM match WITH(NOLOCK) WHERE eventdate = @winlostdate)
	END
	
	-- delete AutoPayoutResult
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'AutoPayoutResult' AND type = 'U')
	BEGIN
		DELETE FROM AutoPayoutResult WITH(ROWLOCK)
		WHERE matchid in (SELECT matchid FROM match WITH(NOLOCK) WHERE eventdate = @winlostdate)
	END
	
	-- delete ProviderResultDetail
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'ProviderResultDetail' AND type = 'U')
	BEGIN
		DELETE FROM ProviderResultDetail WITH(ROWLOCK)
		WHERE matchid in (SELECT matchid FROM match WITH(NOLOCK) WHERE eventdate = @winlostdate)
	END

	-- Delete Odds3rd
	IF	EXISTS (SELECT 1 FROM sys.objects WHERE name = 'Odds3rd' AND type = 'U')
	BEGIN
		DELETE
		FROM	dbo.Odds3rd WITH (ROWLOCK)
		WHERE	matchid IN (SELECT matchid FROM dbo.match WITH (NOLOCK) WHERE eventdate = @Winlostdate);
	END;

	--	Delete oddsES
		-- 20181204@Billy --
	IF	OBJECT_ID('dbo.oddsES', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.oddsES AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	--	Delete ResultDetailES
		-- 20181204@Billy --
	IF	OBJECT_ID('dbo.ResultDetailES', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.ResultDetailES AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	-- Delete [SMP_Market]
		-- 20190325@Billy --
	IF	OBJECT_ID('dbo.SMP_Market', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.SMP_Market AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	-- Delete [SMP_MarketSelection]
		-- 20190325@Billy --
	IF	OBJECT_ID('dbo.SMP_MarketSelection', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.SMP_MarketSelection AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	--	Delete oddsOS
		-- 20190828@Billy --
	IF	OBJECT_ID('dbo.oddsOS', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.oddsOS AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	--	Delete ResultDetailOS
		-- 20190828@Billy --
	IF	OBJECT_ID('dbo.ResultDetailOS', 'U') IS NOT NULL
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM	dbo.ResultDetailOS AS tbl
		WHERE	EXISTS (SELECT 1 FROM dbo.match AS m WITH (NOLOCK) WHERE tbl.matchid = m.matchid AND m.eventdate = @Winlostdate);
	END;

	-- delete match	
	DELETE	tbl WITH (ROWLOCK)
	FROM	dbo.match AS tbl
	WHERE	eventdate = @Winlostdate;

	-- delete outright
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'outright' AND type = 'U')
	BEGIN
		delete from outright
		where eventdate = @winlostdate AND oddsstatus = 'Completed'
	END

		
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'VSOutright' AND type = 'U')
	BEGIN
		delete from VSOutright
		where eventdate = @winlostdate AND EventStatus = 'Completed'
	END

	-- delete EventInfo3rd
	IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'EventInfo3rd' AND type = 'U')
	BEGIN
		DELETE dbo.EventInfo3rd
		WHERE eventdate = @winlostdate  
	END
	
	-- Delete Match3rd
		-- 20171221@Billy --
	IF	OBJECT_ID('dbo.Match3rd', 'U') IS NOT NULL
	BEGIN;
		DELETE	dbo.Match3rd
		WHERE	EventDate = @Winlostdate;
	END;
END
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/