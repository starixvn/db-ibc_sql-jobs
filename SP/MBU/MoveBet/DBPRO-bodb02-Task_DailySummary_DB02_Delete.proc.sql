SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_DailySummary_DB02_Delete]
	@winlostdate datetime
AS
/*
	-- Run on DB02 (ProductDB)
	-- call by TransDB : Task_DailySummary

	Revisions
		-- 20110802@Sylvia: Delete Dot_Admin_Assignment_Operator
		-- 20121031@Sylvia: Delete SS_GameState
		-- 20130520@Victor: Add Delete VSOutright by eventdate
		-- 20130531@Sophia: Put Delete code into ExecRep_APL_01
		-- 20190323@Patrick: Set deadlock priority to high [RedmineId: #113997]
		-- 20210924@July:  Deleting event cause the table to be blocked [RedmineId: #160468]

*/
BEGIN
	SET DEADLOCK_PRIORITY HIGH

	DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topn INT = 2000, @DeletedTarget VARCHAR(100)	= ''
	CREATE TABLE #output (id INT)	
	CREATE TABLE #DeletedList (id INT PRIMARY KEY CLUSTERED,IsDone BIT)
	CREATE TABLE #Match_tmp (Matchid INT PRIMARY KEY)
	
	INSERT INTO #Match_tmp (matchid)
	SELECT Matchid 
	FROM dbo.match AS m WITH (NOLOCK) 
	WHERE m.eventdate = @Winlostdate

	/*
	ResultDetail
	ProviderExternalResultDetailES
	Odds3rd
	odds
	MatchMaxbet
	oddsOS
	ResultDetailOS
	ResultDetail3rd
	ProviderExternalResultDetailOS
	match
	Dot_admin_Assignment_Operator
	ProviderResultDetail
	ResultDetailES
	oddsES
	bingoBall
	ProviderExternalResultDetail
	SMP_MarketSelection
	VSOutright
	AutoPayoutResult
	SMP_Market
	outright
	EventInfo3rd
	Match3rd
	VSRaceInfo
	*/
	---- Table 1: odds
	-- delete odds
	SET @DeletedTarget = 'odds'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT oddsid
	FROM odds o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END
	-- delete bingoball
	SET @DeletedTarget = 'bingoball'
	TRUNCATE TABLE #DeletedList
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.matchid
	FROM bingoball o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

	SET @rowcount = 1
	WHILE @rowcount <> 0
	BEGIN
		TRUNCATE TABLE #output
		SET @ids = NULL

		DELETE TOP(1000) t
		OUTPUT deleted.id INTO #output(id)
		FROM #DeletedList t
		SET @rowcount = @@ROWCOUNT

		SELECT @ids = COALESCE(@ids + '^' + CAST(id AS VARCHAR(50)), CAST(id AS VARCHAR(50)))
		FROM #output  

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- delete Dot_Admin_Assignment_Operator
	SET @DeletedTarget = 'Dot_Admin_Assignment_Operator'
	TRUNCATE TABLE #DeletedList
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.matchid
	FROM Dot_Admin_Assignment_Operator o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid
	
	IF DATEPART(weekday, @winlostdate) = 2
	BEGIN
		INSERT INTO #DeletedList (id,IsDone)
		SELECT matchid
		FROM Dot_Admin_Assignment_Operator o
			LEFT JOIN #DeletedList d ON o.matchid = d.id
		WHERE MatchID NOT IN (SELECT MatchID FROM match WITH(NOLOCK)) 
			AND d.id IS NULL
	END
			
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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete ResultDetail3rd
	SET @DeletedTarget = 'ResultDetail3rd'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.ResultID
	FROM ResultDetail3rd o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete AutoPayoutResult
	SET @DeletedTarget = 'AutoPayoutResult'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.AutoPayoutResultId
	FROM dbo.AutoPayoutResult o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete ProviderResultDetail
	SET @DeletedTarget = 'ProviderResultDetail'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.ProviderResultDetailId
	FROM dbo.ProviderResultDetail o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete Odds3rd
	SET @DeletedTarget = 'Odds3rd'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.oddsid
	FROM dbo.Odds3rd o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete oddsES
	SET @DeletedTarget = 'oddsES'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.oddsid
	FROM dbo.oddsES o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete SMP_MarketSelection
	SET @DeletedTarget = 'SMP_MarketSelection'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.MarketSelectionId
	FROM dbo.SMP_MarketSelection o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete oddsOS
	SET @DeletedTarget = 'oddsOS'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.oddsid
	FROM dbo.oddsOS o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete ProviderExternalResultDetailES
	SET @DeletedTarget = 'ProviderExternalResultDetailES'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.ProviderExternalId
	FROM dbo.ProviderExternalResultDetailES o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete ProviderExternalResultDetailOS
	SET @DeletedTarget = 'ProviderExternalResultDetailOS'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.ProviderExternalId
	FROM dbo.ProviderExternalResultDetailOS o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete ProviderExternalResultDetail
	SET @DeletedTarget = 'ProviderExternalResultDetail'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.ProviderExternalId
	FROM dbo.ProviderExternalResultDetail o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END





	-- Delete match
	SET @DeletedTarget = 'match'
	INSERT INTO #DeletedList (id,IsDone)
	SELECT o.matchid
	FROM dbo.match o WITH (NOLOCK)
		INNER JOIN #Match_tmp m ON m.Matchid = o.matchid

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

		EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids
	END

	-- Delete outright
	SET @DeletedTarget = 'outright'
	SET @ids = NULL
	EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids

	-- Delete VSRaceInfo
	SET @DeletedTarget = 'VSRaceInfo'
	SET @ids = NULL
	EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids

	-- Delete VSOutright
	SET @DeletedTarget = 'VSOutright'
	SET @ids = NULL
	EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids

	-- Delete EventInfo3rd
	SET @DeletedTarget = 'EventInfo3rd'
	SET @ids = NULL
	EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids

	-- Delete Match3rd
	SET @DeletedTarget = 'Match3rd'
	SET @ids = NULL
	EXEC [dbo].[ExecRep_APL_01] @winlostdate = @winlostdate, @DeletedTarget = @DeletedTarget, @ids = @ids

END
GO
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/