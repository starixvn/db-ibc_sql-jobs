USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Event_SyncOdds]    Script Date: 01/19/2015 03:08:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Event_SyncOdds    Script Date: 8/27/2014 10:40:30 PM ******/
/****** Object:  Stored Procedure dbo.Task_Event_SyncOdds    Script Date: 8/27/2014 2:07:35 PM ******/
CREATE PROCEDURE [dbo].[Task_Event_SyncOdds]
AS
/*
Created by: Dan
Date: 2013-05-27
Task: sync odd to Chart DB
DB: DB06/bodb_Chart
Revisions:
	- 20140826@Sophia: Set default of Odds.chartstatus
*/
SET NOCOUNT ON

DECLARE @odssid_min bigint, @oddsid_max bigint, @interval_nonlive_odds int
SET @interval_nonlive_odds  = 15 -- minute 

SELECT @odssid_min = CAST(ISNULL(VValue, 0) as bigint)
FROM dbo.Settings with (rowlock)
WHERE VName = 'syncOdds'	
--print @odssid_min

--for testing
--SELECT @oddsid_max = 4618621779

IF NOT EXISTS (SELECT TOP 1 matchid FROM [dbo].[match_queue] WITH (NOLOCK))
	RETURN

DECLARE @now datetime
SET @now=getdate()

SELECT @oddsid_max = isnull(max(oddsid),@odssid_min)  FROM bodb02.dbo.odds WITH(NOLOCK)

--no new record
IF EXISTS(SELECT 1 FROM bodb02.dbo.odds WITH(NOLOCK)
		WHERE matchid in (SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK))
						AND oddsid>@odssid_min AND oddsid<=@oddsid_max)
BEGIN
	INSERT [dbo].[odds] (
		[oddsid]
      ,[matchid]
      ,[bettype]
      ,[liveindicator]
	  ,hdp1
	  ,hdp2
      ,[changetime]
	  ,chartstatus
	)
	SELECT [oddsid]
      ,[matchid]
      ,[bettype]
      ,[liveindicator]
	  ,hdp1
	  ,hdp2
      ,getdate()
	  ,1
	FROM bodb02.dbo.odds 
	WHERE matchid in (SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK))
		and bettype in (1,5,3)
		and oddsid>@odssid_min and oddsid<=@oddsid_max
END

--insert all previous odds if a match has been added to monitor first time
IF (EXISTS(SELECT 1 FROM [dbo].[match_queue] WITH(NOLOCK) WHERE isPendingSyncOdds = 1))
BEGIN
	DECLARE @match table(matchid int)
	INSERT INTO @match(matchid)
	SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK)  WHERE isPendingSyncOdds = 1

	INSERT [dbo].[odds] (
		[oddsid]
      ,[matchid]
      ,[bettype]
      ,[liveindicator]
	  ,hdp1
	  ,hdp2
      ,[changetime]
	  ,chartstatus
	)
	SELECT [oddsid]
      ,[matchid]
      ,[bettype]
      ,[liveindicator]
	  ,hdp1
	  ,hdp2
      ,getdate()
	  ,1
	FROM bodb02.dbo.odds o
	WHERE matchid in (SELECT matchid FROM @match)
		and bettype in (1,5,3)
		and oddsid<=@oddsid_max
		AND NOT EXISTS(SELECT 1 FROM odds o1 WITH (NOLOCK) WHERE o1.oddsid=o.oddsid )

	UPDATE [match_queue]
	SET isPendingSyncOdds=0
	FROM @match m
	WHERE m.matchid=[match_queue].matchid

END


UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = CAST(CAST(@oddsid_max as bigint) as varchar(200))
WHERE VName = 'syncOdds'
GO


