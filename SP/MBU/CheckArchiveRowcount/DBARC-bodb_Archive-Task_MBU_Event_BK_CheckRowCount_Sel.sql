SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_MBU_Event_BK_CheckRowCount_Sel
						@DateCheck		SMALLDATETIME
					,	@OutputData		VARCHAR(4000)	= ''	OUTPUT
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
		- 20190621@Billy:	Add checking for [SMP_Market] & [SMP_MarkerSelection] - [Redmine: #111421]
		- 20191106@Billy:	Add checking for [Dot_Admin_Assignment_Trader] - [Redmine: #123262]
*/
BEGIN;
	SET NOCOUNT ON;
	DECLARE	@__tempCount TABLE (rowcnt INT, tableName VARCHAR(128));

	--//match
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'match'
	FROM	dbo.match_bk AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//Match3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Match3rd'
	FROM	dbo.Match3rd_bk AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//outright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'outright'
	FROM	dbo.outright_bk AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//VSOutright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'VSOutright'
	FROM	dbo.VSOutright_bk AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//EventInfo3rd_bk
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'EventInfo3rd'
	FROM	dbo.EventInfo3rd_bk AS tbl WITH (NOLOCK)
	WHERE	tbl.eventdate = @DateCheck;

	--//odds
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'odds'
	FROM	dbo.odds_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//BingoBall
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'BingoBall'
	FROM	dbo.BingoBall_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.Matchid = m.matchid);	

	--//match_remark
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'match_remark'
	FROM	dbo.match_remark AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//matchMaxbet
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'matchMaxbet'
	FROM	dbo.matchMaxbet_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);
	
	--//ResultDetail
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ResultDetail'
	FROM	dbo.ResultDetail_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//ResultDetail3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ResultDetail3rd'
	FROM	dbo.ResultDetail3rd_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//AutoPayoutResult
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'AutoPayoutResult'
	FROM	dbo.AutoPayoutResult_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//ProviderResultDetail
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'ProviderResultDetail'
	FROM	dbo.ProviderResultDetail_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Odds3rd
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Odds3rd'
	FROM	dbo.Odds3rd_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Intg_OddsFeed_SettlementAction
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Intg_OddsFeed_SettlementAction'
	FROM	dbo.Intg_OddsFeed_SettlementAction_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Intg_OddsFeed_SettlementAction_Outright
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Intg_OddsFeed_SettlementAction_Outright'
	FROM	dbo.Intg_OddsFeed_SettlementAction_Outright_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.outright_bk AS o WITH (NOLOCK) WHERE o.eventdate = @DateCheck AND tbl.orid = o.orid);

	--//SMP_Market
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'SMP_Market'
	FROM	dbo.SMP_Market_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//SMP_MarketSelection
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'SMP_MarketSelection'
	FROM	dbo.SMP_MarketSelection_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//Dot_Admin_Assignment_Trader
	INSERT INTO	@__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Dot_Admin_Assignment_Trader'
	FROM	dbo.Dot_Admin_Assignment_Trader_bk AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match_bk AS m WITH (NOLOCK) WHERE m.eventdate = @DateCheck AND tbl.matchid = m.matchid);

	--//
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/