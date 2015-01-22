USE [bodb_TGRS]
GO

/****** Object:  StoredProcedure [dbo].[Task_StagingTraderPerformanceByMonth]    Script Date: 01/21/2015 23:54:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_StagingTraderPerformanceByMonth]
	@Month DATE = NULL
	 
AS

/*
 Created:	20140604@Tom.Vo
 Task :		Staging Data on TGRS DB By Month
 DB:		DBTGRS.bodb_TGRS
 Original:  
  
 Revisions:      
   			
 Param's Explanation:  
	 
 Exam:

*/

SET NOCOUNT ON
	
	DECLARE @StartDate DATE,@EndDate Date

	SELECT @StartDate=DATEADD(DD,-DAY(@Month)+1,@Month)

	SELECT @EndDate =DATEADD(DD,-1,DATEADD(MM,1,@StartDate))

	SELECT @Month=@StartDate
 
	DELETE [dbo].[SummaryByTrader_Monthly] WHERE EventDate = @Month

	INSERT INTO [dbo].[SummaryByTrader_Monthly](
		[Eventdate]
		  ,[CustId]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		  )
	SELECT @Month [Eventdate]
		  ,[CustId]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) [BetCount]
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	 FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	 WHERE EventDate BETWEEN @StartDate AND @EndDate
	 GROUP BY [CustId]

	DELETE [dbo].[SummaryByBetType_Monthly]	WHERE EventDate = @Month

	INSERT INTO [dbo].[SummaryByBetType_Monthly]
		([EventDate]
		  ,[LeagueId]
		  ,[BetType]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[LeagueId]
		  ,[BetType]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [LeagueId]
		,[BetType]

	DELETE [dbo].SummaryByLeague_Monthly	WHERE EventDate = @Month

	INSERT INTO [dbo].SummaryByLeague_Monthly
		([EventDate]
		  ,[LeagueId]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[LeagueId]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [LeagueId]

	DELETE [dbo].SummaryByTeam_Monthly	WHERE EventDate = @Month

	INSERT INTO [dbo].SummaryByTeam_Monthly
		([EventDate]
		  ,[TeamId]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[TeamId]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [TeamId]



GO

GRANT EXECUTE ON [dbo].[Task_StagingTraderPerformanceByMonth] TO [bodbTGRSNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_StagingTraderPerformanceByMonth] TO [vnteam] AS [dbo]
GO


