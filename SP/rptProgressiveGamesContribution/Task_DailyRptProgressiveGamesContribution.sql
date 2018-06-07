/*<info serverAlias="DBSUM-bodb_Summary" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptProgressiveGamesContribution]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20180222@Percy
	Task: SP Gen data for rptProgressiveGamesContribution [Redmine: #83787]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180222@Percy: Initialize SP [RedmineID: #83787]
		- 20180420@Percy: Change stake to actual_stake for Contribution formula [RedmineID: #94025]
		- 20180529@Percy: Change Contribution formula [RedmineID: #96053]
		- 20180607@Percy: Change Contribution data type [RedmineID: #96053]

	Param's Explanation:
*/

BEGIN 
	SET NOCOUNT ON 

	DECLARE @Bettype TABLE (ProductID INT, ContributionBettype INT)

	INSERT INTO @Bettype (ProductID, ContributionBettype)
	SELECT ProductID, ContributionBettype
	FROM bodb02.dbo.f_ProgressiveGamesContribution_Bettype_Sel('All')

	/* Get data source */
	CREATE TABLE #rptProgressiveGamesContribution
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
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN @Bettype g ON b.Bettype = g.ContributionBettype
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
	END

	-- Agent - RoleId = 2
	BEGIN
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
		FROM #rptProgressiveGamesContribution
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
		FROM #rptProgressiveGamesContribution
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
		FROM #rptProgressiveGamesContribution
		WHERE RoleId = 1 
		GROUP BY
			WinlostDate,
			SRecommend,
			ProductId,
			GameId
	END

	/* Gen data */
	BEGIN
		MERGE dbo.rptProgressiveGamesContribution AS TARGET
		USING #rptProgressiveGamesContribution AS SOURCE
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

	DROP TABLE #rptProgressiveGamesContribution
END
GO