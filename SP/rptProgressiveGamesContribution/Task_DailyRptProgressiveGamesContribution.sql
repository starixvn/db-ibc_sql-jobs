/*<info serverAlias="DBSUM-bodb_Summary" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptProgressiveGamesContribution]
	@WinlostDate SMALLDATETIME
AS

/*
	Created by: 20180222@Sophia
	Task: SP Gen data for rptProgressiveGamesContribution [Redmine: #83787]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180222@Sophia: Initialize SP [RedmineID: #83787]

	Param's Explanation:
*/

BEGIN 
	SET NOCOUNT ON 

	DECLARE @Bettype TABLE (ProductID INT, Bettype INT)

	INSERT INTO @Bettype (ProductID, Bettype)
	SELECT ProductID, Bettype
	FROM bodb02.dbo.f_ProgressiveGamesContribution_Bettype_Sel('All')

	-- Delete old data
	DELETE dbo.rptProgressiveGamesContribution WITH (ROWLOCK, UPDLOCK) WHERE WinlostDate = @WinlostDate

	-- Member - RoleId = 1
	INSERT INTO dbo.rptProgressiveGamesContribution (
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
	FROM		bodb02.dbo.BettransRNG b WITH (NOLOCK)
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
	INSERT INTO dbo.rptProgressiveGamesContribution (
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
	FROM	dbo.rptProgressiveGamesContribution b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate,
				b.Recommend,
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId
				
	-- Master - RoleId = 3
	INSERT INTO dbo.rptProgressiveGamesContribution (
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
	FROM	dbo.rptProgressiveGamesContribution b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate, 
				b.MRecommend,
				b.SRecommend,
				ProductId,
				GameId
							
	-- Super - RoleId = 4
	INSERT INTO dbo.rptProgressiveGamesContribution (
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
	FROM	dbo.rptProgressiveGamesContribution b WITH (NOLOCK)
	WHERE	b.RoleId = 1 
			AND b.WinlostDate = @WinlostDate
	GROUP BY	b.WinlostDate, 
				b.SRecommend,
				ProductId,
				GameId
END
GO