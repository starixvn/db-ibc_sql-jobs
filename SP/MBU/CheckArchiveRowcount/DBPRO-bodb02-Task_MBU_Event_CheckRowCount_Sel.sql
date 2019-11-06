SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_MBU_Event_CheckRowCount_Sel
						@DateCheck		SMALLDATETIME
					,	@OutputData		VARCHAR(4000)	= ''	OUTPUT
AS
/*
	Created:	20180925@Patrick
	Task:		Check consistency data for archiving process
	Database:	DBPRO.bodb02

	Revisions:
		- 20180926@Patrick:	Initial - [Redmine: #101207]
		- 20190621@Billy:	Add checking for [SMP_Market] & [SMP_MarkerSelection] - [Redmine: #111421]
		- 20191106@Billy:	Add checking for [Dot_Admin_Assignment_Trader] - [Redmine: #123262]
*/
BEGIN;
	SET NOCOUNT ON;
	DECLARE	@__tempCount TABLE (rowcnt INT, tableName VARCHAR(128));

	--//match
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'match'
	FROM	dbo.match14 AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//Match3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Match3rd'
	FROM	dbo.Match3rd14 AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//outright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'outright'
	FROM	dbo.outright14 AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//VSOutright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'VSOutright'
	FROM	dbo.VSOutright14 AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//EventInfo3rd14
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'EventInfo3rd'
	FROM	dbo.EventInfo3rd14 AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//odds
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'odds'
	FROM	dbo.odds14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//BingoBall
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'BingoBall'
	FROM	dbo.BingoBall14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.Matchid = m.matchid);	

	--//match_remark
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'match_remark'
	FROM	dbo.match_remark AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//matchMaxbet
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'matchMaxbet'
	FROM	dbo.matchMaxbet14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);
	
	--//ResultDetail
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ResultDetail'
	FROM	dbo.ResultDetail14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//ResultDetail3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ResultDetail3rd'
	FROM	dbo.ResultDetail3rd14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//AutoPayoutResult
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'AutoPayoutResult'
	FROM	dbo.AutoPayoutResult14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//ProviderResultDetail
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ProviderResultDetail'
	FROM	dbo.ProviderResultDetail14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Odds3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Odds3rd'
	FROM	dbo.Odds3rd14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Intg_OddsFeed_SettlementAction
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Intg_OddsFeed_SettlementAction'
	FROM	dbo.Intg_OddsFeed_SettlementAction AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Intg_OddsFeed_SettlementAction_Outright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Intg_OddsFeed_SettlementAction_Outright'
	FROM	dbo.Intg_OddsFeed_SettlementAction_Outright AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.outright14 AS o WITH (NOLOCK) WHERE o.eventdate = @DateCheck AND tbl.orid = o.orid);

	--//SMP_Market
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'SMP_Market'
	FROM	dbo.SMP_Market14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//SMP_MarketSelection
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'SMP_MarketSelection'
	FROM	dbo.SMP_MarketSelection14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Dot_Admin_Assignment_Trader
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Dot_Admin_Assignment_Trader'
	FROM	dbo.Dot_Admin_Assignment_Trader AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//
	SELECT	@OutputData = (
		SELECT	[r]		= rowcnt
			,	[t]		= tableName
		FROM	@__tempCount
		FOR XML RAW ('r')
	);

END;
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/