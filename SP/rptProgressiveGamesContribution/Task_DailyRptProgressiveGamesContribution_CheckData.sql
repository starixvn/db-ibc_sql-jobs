/*<info serverAlias="DBSUM-bodb_Summary" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptProgressiveGamesContribution_CheckData]
	@WinlostDate		SMALLDATETIME,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created by: 20180222@Sophia.Nguyen
	Task: Job Gen data for rptProgressiveGamesContribution [Redmine: #83787]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180222@Sophia: Initialize SP [RedmineID: #83787]

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

	-- Check MB has done yet
	DECLARE @MBStatusID TINYINT = 1

	EXEC bodb02.dbo.Task_MoveBets_Status @StatusID = @MBStatusID OUTPUT

	IF @MBStatusID = 0 -- this day not have MB
	BEGIN
		RETURN
	END
	ELSE IF @MBStatusID = 1 -- MB is running
	BEGIN
		RAISERROR('Move bets is processing. Automatically retry after 15mins.', 16, 1)
		RETURN
	END

	CREATE TABLE #Source
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
		Contribution	MONEY,
		ContributionA	MONEY,
		ContributionM	MONEY,
		ContributionS	MONEY
	)

	CREATE TABLE #UpdateDate
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
		Contribution	MONEY,
		ContributionA	MONEY,
		ContributionM	MONEY,
		ContributionS	MONEY
	)

	DECLARE @Bettype TABLE (ProductID INT, Bettype INT)

	INSERT INTO @Bettype (ProductID, Bettype)
	SELECT ProductID, Bettype
	FROM bodb02.dbo.f_ProgressiveGamesContribution_Bettype_Sel('All')

	-- Get data source
	INSERT INTO #Source (
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
				ContributionS)

	SELECT		b.WinlostDate,
				b.CustId,
				1 AS RoleId,
				b.Recommend,
				b.MRecommend,
				b.SRecommend,
				g.ProductId,
				b.GameID,
				COUNT(b.TransID) AS Betcount,
				SUM(b.Stake) AS Turnover,
				SUM(b.Stake * b.ContributionRate) AS Contribution,
				-SUM(b.Stake * b.ContributionRate * apositiontaking) AS ContributionA,
				-SUM(b.Stake * b.ContributionRate * mpositiontaking) AS ContributionM,
				-SUM(b.Stake * b.ContributionRate * spositiontaking) AS ContributionS
	FROM		bodb02.dbo.BettransRnG14 b WITH (NOLOCK)
		INNER JOIN @Bettype g ON g.Bettype = b.GameId	
	WHERE	b.WinlostDate = @WinlostDate
			AND b.StatusID NOT IN (0,1,102,101,103)		 
	GROUP BY 	b.WinlostDate,
				b.CustId,
				b.Recommend,
				b.MRecommend,
				b.SRecommend,
				g.ProductId,
				b.GameID

	-- Agent - RoleId = 2
	INSERT INTO #Source (
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
				ContributionS)

	SELECT		b.WinlostDate,
				b.Recommend AS CustId,
				2 AS RoleId,
				b.Recommend,
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId,
				SUM(Betcount) AS Betcount,
				SUM(Turnover) AS Turnover,
				SUM(Contribution) AS Contribution,
				SUM(ContributionA) AS ContributionA,
				SUM(ContributionM) AS ContributionM,
				SUM(ContributionS) AS ContributionS
	FROM	#Source b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate,
				b.Recommend,
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId
				
	-- Master - RoleId = 3
	INSERT INTO #Source (
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
				ContributionS)

	SELECT		b.WinlostDate,
				b.MRecommend AS CustId,
				3 AS RoleId,
				0 AS Recommend,
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId,
				SUM(Betcount) AS Betcount,
				SUM(Turnover) AS Turnover,
				SUM(Contribution) AS Contribution,
				SUM(ContributionA) AS ContributionA,
				SUM(ContributionM) AS ContributionM,
				SUM(ContributionS) AS ContributionS
	FROM	#Source b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate, 
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId
							
	-- Super - RoleId = 4
	INSERT INTO #Source (
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
				ContributionS)

	SELECT		b.WinlostDate,
				b.SRecommend AS CustId,
				4 AS RoleId,
				0 AS Recommend,
				0 AS MRecommend,
				b.SRecommend,
				ProductId,
				GameId,
				SUM(Betcount) AS Betcount,
				SUM(Turnover) AS Turnover,
				SUM(Contribution) AS Contribution,
				SUM(ContributionA) AS ContributionA,
				SUM(ContributionM) AS ContributionM,
				SUM(ContributionS) AS ContributionS
	FROM	#Source b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate, 
				b.SRecommend,
				ProductId,
				GameId

	-- Compare data
	INSERT INTO #UpdateDate (
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
				ContributionS)
	SELECT
		s.WinlostDate,
		CASE
			WHEN s.CustId IS NULL THEN -1
			WHEN rpt.CustId IS NULL THEN -2
			ELSE s.CustId END AS CustId,
		s.RoleId,
		s.Recommend,
		s.MRecommend,
		s.SRecommend,
		s.ProductId,
		s.GameId,
		s.Betcount,
		s.Turnover,
		s.Contribution,
		s.ContributionA,
		s.ContributionM,
		s.ContributionS
	FROM #Source s
		FULL OUTER JOIN dbo.rptProgressiveGamesContribution rpt WITH (NOLOCK)
			ON s.CustId = rpt.CustId AND s.WinlostDate = rpt.WinlostDate AND s.ProductId = rpt.ProductId AND s.GameId = s.GameId
	WHERE
		rpt.WinlostDate = @WinlostDate
		AND (
			s.CustId IS NULL OR rpt.CustId IS NULL
			OR s.Betcount <> rpt.Betcount
			OR s.Turnover <> rpt.Turnover
			OR s.Contribution <> rpt.Contribution
			OR s.ContributionA <> rpt.ContributionA
			OR s.ContributionM <> rpt.ContributionM
			OR s.ContributionS <> rpt.ContributionS
		)

	IF EXISTS (SELECT TOP 1 1 FROM #UpdateDate)
	BEGIN
		IF @IsCheckDataOnly = 1 --just check data
		BEGIN
			SELECT 'Wrong data on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
		ELSE -- correct data
		BEGIN
			DELETE dbo.rptProgressiveGamesContribution WITH (ROWLOCK, UPDLOCK) WHERE WinlostDate = @WinlostDate

			INSERT INTO dbo.rptProgressiveGamesContribution
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
			FROM #UpdateDate
			WHERE CustId <> -1
		END
	END
END
GO