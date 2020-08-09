/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptProgressiveGamesContribution_CheckData]
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20180222@Percy
	Task: SP check data for rptProgressiveGamesContribution [Redmine: #83787]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180222@Percy: Initialize SP [RedmineID: #83787]
		- 20180420@Percy: Change stake to actual_stake for Contribution formula [RedmineID: #94025]
		- 20180529@Percy: Change Contribution formula [RedmineID: #96053]
		- 20180607@Percy: Change Contribution data type [RedmineID: #96053]
		- 20200809@Sophia: Add PP Jackpot contribution [Redmine: #138483]
		
  
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
		
	DECLARE @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	SELECT @MoveBetsDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK)
		
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
		
	IF @winlostdate NOT BETWEEN @BalanceUpDay AND @MoveBetsDay
	BEGIN
		SELECT 999 AS ErrCode, 'Parameter Winlostdate is invalid!' AS ErrMsg
		RETURN
	END

	DECLARE @Bettype TABLE (ProductId INT, bettype INT, ContributionBettype INT)

	INSERT INTO @Bettype (ProductId, bettype, ContributionBettype)
	SELECT ProductId, BetType, ContributionBettype FROM bodb02.dbo.f_ProgressiveGamesContribution_Bettype_Sel('All')
	l;
	/* Get data source */
	CREATE TABLE #rptProgressiveGamesContribution_Source
	(
		WinlostDate		SMALLDATETIME,
		CustId			INT,
		RoleId			INT,
		Recommend		INT,
		MRecommend		INT,
		SRecommend		INT,
		ProductId		SMALLINT,
		GameId			SMALLINT,
		Betcount		INT,
		Turnover		MONEY,
		Contribution	DECIMAL(19,8),
		ContributionA	MONEY,
		ContributionM	MONEY,
		ContributionS	MONEY
	)

	-- Member - RoleId = 1
	BEGIN
		----RNG Casino
		INSERT INTO #rptProgressiveGamesContribution_Source
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)

		SELECT
			b.WinlostDate,
			b.CustId,
			1 AS RoleId,
			b.Recommend,
			b.MRecommend,
			b.SRecommend,
			g.ProductId,
			b.Bettype,
			COUNT(b.TransID) AS Betcount,
			SUM(ISNULL(b.oddsspread, 0)),
			SUM(ISNULL(CONVERT(DECIMAL, b.betid)/100000000, 0)),
			SUM(ISNULL(b.awinlost, 0)) AS ContributionA,
			SUM(ISNULL(b.mwinlost, 0)) AS ContributionM,
			SUM(ISNULL(b.swinlost, 0)) AS ContributionS
		FROM bodb02.dbo.Bettrans14 b WITH (NOLOCK)
			INNER JOIN @Bettype g ON b.Bettype = g.ContributionBettype AND g.ProductID = 6
		WHERE b.WinlostDate = @WinlostDate
			AND b.StatusID NOT IN (0,1,102,101,103)		 
		GROUP BY
			b.WinlostDate,
			b.CustId,
			b.Recommend,
			b.MRecommend,
			b.SRecommend,
			g.ProductId,
			b.Bettype
			
			
		-----PP Jackpot 
		INSERT INTO #rptProgressiveGamesContribution
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)
		SELECT
			bc.WinlostDate,
			bc.CustId,
			1 AS RoleId,
			bc.Recommend,
			bc.MRecommend,
			bc.SRecommend,
			sc.ProductId,
			bb.GameId,
			COUNT(bc.TransID) AS Betcount,
			SUM(ISNULL(bc.BetStake, 0)),
			SUM(ISNULL(bc.ContributionStake3rd, 0)),
			SUM(ISNULL(bc.awinlost, 0)) AS ContributionA,
			SUM(ISNULL(bc.mwinlost, 0)) AS ContributionM,
			SUM(ISNULL(bc.swinlost, 0)) AS ContributionS
		FROM bodb02.dbo.bettransRNG14 bc WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettransRNG14 bb WITH (NOLOCK) ON bc.RefNo2 = bb.TransId
			INNER JOIN @Bettype sc ON bc.GameId = sc.ContributionBettype AND sc.ProductID = 32
			INNER JOIN @Bettype sb ON bb.GameId = sb.bettype AND sb.ProductID = 32 
		WHERE bc.WinlostDate = @WinlostDate
			AND bc.StatusID IN (111,112,113)
		GROUP BY
			bc.WinlostDate,
			bc.CustId,
			bc.Recommend,
			bc.MRecommend,
			bc.SRecommend,
			sc.ProductId,
			bb.GameId
	END

	-- Agent - RoleId = 2
	BEGIN
		INSERT INTO #rptProgressiveGamesContribution_Source
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)

		SELECT
			WinlostDate,
			Recommend AS CustId,
			2 AS RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			SUM(Betcount) AS Betcount,
			SUM(Turnover) AS Turnover,
			SUM(Contribution) AS Contribution,
			SUM(ContributionA) AS ContributionA,
			SUM(ContributionM) AS ContributionM,
			SUM(ContributionS) AS ContributionS
		FROM #rptProgressiveGamesContribution_Source
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId
	END
				
	-- Master - RoleId = 3
	BEGIN
		INSERT INTO #rptProgressiveGamesContribution_Source
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)

		SELECT
			WinlostDate,
			MRecommend AS CustId,
			3 AS RoleId,
			0 AS Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			SUM(Betcount) AS Betcount,
			SUM(Turnover) AS Turnover,
			SUM(Contribution) AS Contribution,
			SUM(ContributionA) AS ContributionA,
			SUM(ContributionM) AS ContributionM,
			SUM(ContributionS) AS ContributionS
		FROM #rptProgressiveGamesContribution_Source
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			MRecommend,
			SRecommend,
			ProductId,
			GameId
	END
							
	-- Super - RoleId = 4
	BEGIN
		INSERT INTO #rptProgressiveGamesContribution_Source
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)

		SELECT
			WinlostDate,
			SRecommend AS CustId,
			4 AS RoleId,
			0 AS Recommend,
			0 AS MRecommend,
			SRecommend,
			ProductId,
			GameId,
			SUM(Betcount) AS Betcount,
			SUM(Turnover) AS Turnover,
			SUM(Contribution) AS Contribution,
			SUM(ContributionA) AS ContributionA,
			SUM(ContributionM) AS ContributionM,
			SUM(ContributionS) AS ContributionS
		FROM #rptProgressiveGamesContribution_Source
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			SRecommend,
			ProductId,
			GameId
	END

	/* Get data target */
	CREATE TABLE #rptProgressiveGamesContribution_Target
	(
		WinlostDate		SMALLDATETIME,
		CustId			INT,
		RoleId			INT,
		Recommend		INT,
		MRecommend		INT,
		SRecommend		INT,
		ProductId		SMALLINT,
		GameId			SMALLINT,
		Betcount		INT,
		Turnover		MONEY,
		Contribution	DECIMAL(19,8),
		ContributionA	MONEY,
		ContributionM	MONEY,
		ContributionS	MONEY
	)

	BEGIN
		INSERT INTO #rptProgressiveGamesContribution_Target
		(
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		)
		SELECT
			WinlostDate,
			CustId,
			RoleId,
			Recommend,
			MRecommend,
			SRecommend,
			ProductId,
			GameId,
			Betcount,
			Turnover,
			Contribution,
			ContributionA,
			ContributionM,
			ContributionS
		FROM dbo.rptProgressiveGamesContribution WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
	END

	/* Compare data */
	CREATE NONCLUSTERED INDEX IX_CustID ON #rptProgressiveGamesContribution_Source (CustId, ProductId, GameId)
	CREATE NONCLUSTERED INDEX IX_CustID ON #rptProgressiveGamesContribution_Target (CustId, ProductId, GameId)

	IF EXISTS (
		SELECT 1
		FROM #rptProgressiveGamesContribution_Source s
			FULL OUTER JOIN #rptProgressiveGamesContribution_Target t
				ON s.CustId = t.CustId AND s.ProductId = t.ProductId AND s.GameId = t.GameId AND s.WinlostDate = t.WinlostDate
		WHERE
				s.CustId IS NULL
				OR t.CustId IS NULL
				OR s.Betcount <> t.Betcount
				OR s.Turnover <> t.Turnover
				OR s.Contribution <> t.Contribution
				OR s.ContributionA <> t.ContributionA
				OR s.ContributionM <> t.ContributionM
				OR s.ContributionS <> t.ContributionS
	)
	BEGIN
		IF @IsCheckDataOnly = 1 --just check data
		BEGIN
			SELECT 'Wrong data on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
		ELSE -- correct data
		BEGIN
			MERGE dbo.rptProgressiveGamesContribution AS TARGET
			USING #rptProgressiveGamesContribution_Source AS SOURCE
				ON		TARGET.WinlostDate	= SOURCE.WinlostDate
					AND TARGET.CustId		= SOURCE.CustId
					AND TARGET.ProductId	= SOURCE.ProductId
					AND TARGET.GameId		= SOURCE.GameId
			WHEN MATCHED THEN
				UPDATE SET
					TARGET.RoleId			= SOURCE.RoleId,
					TARGET.Recommend		= SOURCE.Recommend,
					TARGET.MRecommend		= SOURCE.MRecommend,
					TARGET.SRecommend		= SOURCE.SRecommend,
					TARGET.Betcount			= SOURCE.Betcount,
					TARGET.Turnover			= SOURCE.Turnover,
					TARGET.Contribution		= SOURCE.Contribution,
					TARGET.ContributionA	= SOURCE.ContributionA,
					TARGET.ContributionM	= SOURCE.ContributionM,
					TARGET.ContributionS	= SOURCE.ContributionS
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(
					WinlostDate,CustId,RoleId,
					Recommend,MRecommend,SRecommend,
					ProductId,GameId,Betcount,Turnover,
					Contribution,ContributionA,ContributionM,ContributionS
				)
				VALUES
				(
					SOURCE.WinlostDate,SOURCE.CustId,SOURCE.RoleId,
					SOURCE.Recommend,SOURCE.MRecommend,SOURCE.SRecommend,
					SOURCE.ProductId,SOURCE.GameId,SOURCE.Betcount,SOURCE.Turnover,
					SOURCE.Contribution,SOURCE.ContributionA,SOURCE.ContributionM,SOURCE.ContributionS
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
				DELETE;
		END
	END

	DROP TABLE #rptProgressiveGamesContribution_Source
	DROP TABLE #rptProgressiveGamesContribution_Target
END
GO