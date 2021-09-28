/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[ExecRep_APL_01]
	  @DeletedTarget	VARCHAR(100)	= ''
	, @ids				VARCHAR(MAX)	= ''
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
		- 20200622@Patrick: Add more table VSRaceInfo [Redmine: #135963]
		- 20200803@Patrick: Add remove data on VSRaceInfo part [Redmine: #135963]
		- 20200729@Brice:	Add table ProviderExternalResultDetailES [Redmine: #138380]
		- 20200826@Brice:		Add table ProviderExternalResultDetailOS [Redmine: #139849]
		- 20201221@Brice:		Add table ProviderExternalResultDetail [Redmine: #145651]
		- 20210914@Patrick: Support bitcoin project: Odds3rd & ResultDetail3rd [Redmine: #159842]
		- 20210924@July:  Deleting event cause the table to be blocked [Redmine: #160468]
*/ 
BEGIN

	SET NOCOUNT ON 
	IF @@SERVERNAME = 'DBCLS1\SDBPROD' RETURN --- ProdDB of Apollo
	
	IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'match' AND type = 'U') RETURN -- no match table, do nothing
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = @DeletedTarget AND type = 'U') RETURN

	DECLARE @idList TABLE(id INT, id2 VARCHAR(20), id3 INT)
	DECLARE @xmlData XML
	SET @xmlData = CONVERT(XML, @ids)

	INSERT INTO @idList (id, id2, id3)
	SELECT T.C.value('./@c1', 'INT') AS id
			,T.C.value('./@c2', 'VARCHAR(20)') AS id2
			,T.C.value('./@c3', 'INT') AS id3
	FROM @xmlData.nodes('/root/r') AS T(C)
	OPTION (OPTIMIZE FOR (@xmlData = NULL))

	IF @DeletedTarget = 'odds'
	BEGIN
		DELETE FROM dbo.odds WITH(ROWLOCK) WHERE oddsid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'bingoball'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.bingoball AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.Seq = i.id3)
		RETURN
	END
	IF @DeletedTarget = 'Dot_Admin_Assignment_Operator'
	BEGIN
		DELETE FROM dbo.Dot_Admin_Assignment_Operator WITH(ROWLOCK) WHERE id IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'MatchMaxbet'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.MatchMaxbet AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.BetType = i.id3)
		RETURN
	END
	IF @DeletedTarget = 'ResultDetail'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.ResultDetail AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.ResourceID = i.id2)
		RETURN
	END
	IF @DeletedTarget = 'ResultDetail3rd'
	BEGIN
		DELETE FROM dbo.ResultDetail3rd WITH(ROWLOCK) WHERE ResultID IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'AutoPayoutResult'
	BEGIN
		DELETE FROM dbo.AutoPayoutResult WITH(ROWLOCK) WHERE AutoPayoutResultId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'ProviderResultDetail'
	BEGIN
		DELETE FROM dbo.ProviderResultDetail WITH(ROWLOCK) WHERE ProviderResultDetailId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'Odds3rd'
	BEGIN
		DELETE FROM dbo.Odds3rd WITH(ROWLOCK) WHERE oddsid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'oddsES'
	BEGIN
		DELETE FROM dbo.oddsES WITH(ROWLOCK) WHERE oddsid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'ResultDetailES'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.ResultDetailES AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.ResourceID = i.id2)
		RETURN
	END
	IF @DeletedTarget = 'SMP_Market'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.SMP_Market AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.MarketId = i.id2 AND tbl.VendorId = i.id3)
		RETURN
	END
	IF @DeletedTarget = 'SMP_MarketSelection'
	BEGIN
		DELETE FROM dbo.SMP_MarketSelection WITH(ROWLOCK) WHERE MarketSelectionId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'oddsOS'
	BEGIN
		DELETE FROM dbo.oddsOS WITH(ROWLOCK) WHERE oddsid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'ResultDetailOS'
	BEGIN
		DELETE tbl WITH (ROWLOCK)
		FROM dbo.ResultDetailOS AS tbl
		WHERE EXISTS (SELECT 1 FROM @idList i WHERE tbl.Matchid = i.id AND tbl.ResourceID = i.id2)
		RETURN
	END
	IF @DeletedTarget = 'ProviderExternalResultDetailES'
	BEGIN
		DELETE FROM dbo.ProviderExternalResultDetailES WITH(ROWLOCK) WHERE ProviderExternalId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'ProviderExternalResultDetailOS'
	BEGIN
		DELETE FROM dbo.ProviderExternalResultDetailOS WITH(ROWLOCK) WHERE ProviderExternalId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'ProviderExternalResultDetail'
	BEGIN
		DELETE FROM dbo.ProviderExternalResultDetail WITH(ROWLOCK) WHERE ProviderExternalId IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'match'
	BEGIN
		DELETE FROM dbo.match WITH(ROWLOCK) WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'outright'
	BEGIN
		DELETE FROM dbo.outright WITH(ROWLOCK) WHERE orid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'VSRaceInfo'
	BEGIN
		DELETE FROM dbo.VSRaceInfo WITH(ROWLOCK) WHERE EventID IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'VSOutright'
	BEGIN
		DELETE FROM VSOutright WITH(ROWLOCK) WHERE Orid IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'EventInfo3rd'
	BEGIN
		DELETE FROM dbo.EventInfo3rd WITH(ROWLOCK) WHERE EventInfo3rdID IN (SELECT id FROM @idList)
		RETURN
	END
	IF @DeletedTarget = 'Match3rd'
	BEGIN
		DELETE FROM dbo.Match3rd WITH(ROWLOCK) WHERE Match3rdId IN (SELECT id FROM @idList)
		RETURN
	END
END
GO
