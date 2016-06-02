SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE	[dbo].[Task_StagingTraderPerformanceByMonth]
					@Month DATE = NULL
AS
/*
	Created:	20140604@Tom.Vo
	Task :		Staging Data on TGRS DB By Month
	DB:			DBTGRS.bodb_TGRS
	Original:  
  
	Revisions:      
		- 20141203@Tom.Vo:	Staging data with new requirement
		- 20160307@Billy:	Add new field Spread for staging data - [Redmine: #53240]
   			
	Param's Explanation:  
	
	Exam:

*/

SET NOCOUNT ON;
	
	DECLARE @StartDate DATE,@EndDate Date;

	SELECT @StartDate=DATEADD(DD,-DAY(@Month)+1,@Month);

	SELECT @EndDate =DATEADD(DD,-1,DATEADD(MM,1,@StartDate));

	SELECT @Month=@StartDate;
 
	DELETE [dbo].[SummaryByTrader_Monthly] WHERE EventDate = @Month;

	INSERT INTO [dbo].[SummaryByTrader_Monthly](
		[Eventdate]
		  ,[CustId]
		   ,[WorkShift]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		  )
	SELECT @Month [Eventdate]
		  ,[CustId]
		   ,[WorkShift]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) [BetCount]
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	 FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	 WHERE EventDate BETWEEN @StartDate AND @EndDate
	 GROUP BY [CustId]
		   ,[WorkShift];

	DELETE [dbo].[SummaryByBetType_Monthly]	WHERE EventDate = @Month;

	INSERT INTO [dbo].[SummaryByBetType_Monthly]
		([EventDate]
		  ,[LeagueId]
		  ,[BetType]
		   ,[WorkShift]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[LeagueId]
		  ,[BetType]
		   ,[WorkShift]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [LeagueId]
		,[BetType]
		   ,[WorkShift];

	DELETE [dbo].SummaryByLeague_Monthly	WHERE EventDate = @Month;

	INSERT INTO [dbo].SummaryByLeague_Monthly
		([EventDate]
		  ,[LeagueId]
		   ,[WorkShift]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[LeagueId]
		   ,[WorkShift]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [LeagueId]
		   ,[WorkShift];

	DELETE [dbo].SummaryByTeam_Monthly	WHERE EventDate = @Month;

	INSERT INTO [dbo].SummaryByTeam_Monthly
		([EventDate]
		  ,[TeamId]
		   ,[WorkShift]
		  ,[Stake]
		  ,[WinLost]
		  ,[Comm]
		  ,[BetCount]
		  ,[MatchCount]
		)
	SELECT @Month [EventDate]
		  ,[TeamId]
		   ,[WorkShift]
		  ,SUM([Stake]) [Stake]
		  ,SUM([WinLost]) [WinLost]
		  ,SUM([Comm]) [Comm]
		  ,SUM([BetCount]) BetCount
		  ,COUNT(DISTINCT [MatchId])[MatchCount]
	  FROM [dbo].[TraderPerformance] WITH(NOLOCK)
	  WHERE EventDate BETWEEN @StartDate AND @EndDate
	  GROUP BY [TeamId]
		   ,[WorkShift];


GO

GRANT EXECUTE ON [dbo].[Task_StagingTraderPerformanceByMonth] TO [bodbTGRSNet] AS [dbo];
GO