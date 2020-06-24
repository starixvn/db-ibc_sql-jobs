SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[ExecRep_APL_03] (
						@winlostdate		DATETIME
					,	@DeletedTarget		VARCHAR(100)	= ''
					,	@ids				VARCHAR(MAX)	= ''
					)
AS
/*
	Created: @Lukas20171011
	Task: delete event14 data in Friday routine task

	Revisions:
		- 20171221@Billy:	Add Match3rd14 table - [Redmine: #88506]
		- 20181204@Billy:	Add [oddsES14] & [ResultDetailES14] tables - [Redmine: #105816]
		- 20190325@Billy:	Add [SMP_Market] & [SMP_MarketSelection] tables - [Redmine: #109926]
		- 20190925@Billy:	Add [Dot_Admin_Assignment_Trader] table - [Redmine: #117014]
		- 20190911@Billy:	Add [oddsOS14] & [ResultDetailOS14] tables - [Redmine: #119257]
		- 20200622@Patrick: Add more table VSRaceInfo [Redmine: #135963]
*/
BEGIN
	SET NOCOUNT ON 

	-- check existing table
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = @DeletedTarget AND type = 'U') RETURN

	DECLARE @idList TABLE(id INT)
	DECLARE @xmlData XML
	SET @xmlData = CONVERT(XML, REPLACE('<root><r t="' + @ids + '"/></root>', '^', '"/><r t="'))

	INSERT INTO @idList (id)
	SELECT T.C.value('./@t', 'INT') AS id
	FROM @xmlData.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@xmlData = NULL))


	IF @DeletedTarget = 'odds14'
	BEGIN
		DELETE FROM dbo.odds14  WHERE oddsid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'BingoBall14'
	BEGIN
		DELETE FROM dbo.BingoBall14 WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'matchMaxbet14'
	BEGIN
		DELETE FROM matchMaxbet14 WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'ResultDetail14'
	BEGIN
		DELETE FROM ResultDetail14 WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'ResultDetail3rd14'
	BEGIN
		DELETE FROM ResultDetail3rd14 WHERE ResultID IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'AutoPayoutResult14'
	BEGIN
		DELETE FROM AutoPayoutResult14 
		WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'ProviderResultDetail14'
	BEGIN
		DELETE FROM ProviderResultDetail14 
		WHERE matchid IN (SELECT id FROM @idList)
		RETURN
	END

	IF @DeletedTarget = 'Odds3rd14'
	BEGIN
		DELETE FROM	dbo.Odds3rd14
		WHERE	oddsid IN (SELECT id FROM @idList)	
		RETURN
	END

	IF @DeletedTarget = 'outright14'
	BEGIN
		DELETE FROM dbo.outright14 WHERE Orid IN (SELECT id FROM @idList)	
		RETURN
	END

	IF @DeletedTarget = 'VSRaceInfo14'
	BEGIN
		DELETE FROM dbo.VSRaceInfo14 WHERE EventID IN (SELECT id FROM @idList)	
		RETURN
	END

	IF @DeletedTarget = 'VSOutright14'
	BEGIN
		DELETE FROM dbo.VSOutright14 WHERE Orid IN (SELECT id FROM @idList)	
		RETURN
	END

	IF @DeletedTarget = 'EventInfo3rd14'
	BEGIN
		DELETE FROM dbo.EventInfo3rd14 WHERE EventInfo3rdID IN (SELECT id FROM @idList)	 
		RETURN
	END

	IF @DeletedTarget = 'match14'
	BEGIN
		DELETE FROM dbo.match14 WHERE matchid IN (SELECT id FROM @idList)	 
		RETURN
	END

	-- 20171221@Billy -- Add Match3rd14
	IF	@DeletedTarget = 'Match3rd14'
	BEGIN;
		DELETE	dbo.Match3rd14
		WHERE	Match3rdId IN (SELECT id FROM @idList);

		RETURN;
	END;

	--20181204@Billy:	Add oddsES14
	IF	@DeletedTarget = 'oddsES14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.oddsES14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.oddsid = il.id;
	END;

	--20181204@Billy:	Add ResultDetailES14
	IF	@DeletedTarget = 'ResultDetailES14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.ResultDetailES14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.MatchID = il.id;
	END;

	-- 20190325@Billy:	Add [SMP_Market14]
	IF	@DeletedTarget = 'SMP_Market14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.SMP_Market14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.MatchID = il.id;
	END;

	-- 20190325@Billy:	Add [SMP_MarketSelection14]
	IF	@DeletedTarget = 'SMP_MarketSelection14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.SMP_MarketSelection14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.MarketSelectionId = il.id;
	END;

	-- 20190925@Billy:	Add [Dot_Admin_Assignment_Trader]
	IF	@DeletedTarget = 'Dot_Admin_Assignment_Trader'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.Dot_Admin_Assignment_Trader AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.ID = il.id;
	END;

	--20190911@Billy:	Add oddsOS14
	IF	@DeletedTarget = 'oddsOS14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.oddsOS14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.oddsid = il.id;
	END;

	--20190911@Billy:	Add ResultDetailOS14
	IF	@DeletedTarget = 'ResultDetailOS14'
	BEGIN;
		DELETE	tbl WITH (ROWLOCK)
		FROM		dbo.ResultDetailOS14 AS tbl
		INNER JOIN	@idList AS il
				ON	tbl.MatchID = il.id;
	END;
END;
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/