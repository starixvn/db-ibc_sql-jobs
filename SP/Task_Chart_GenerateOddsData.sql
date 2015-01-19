USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Chart_GenerateOddsData]    Script Date: 01/19/2015 02:53:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Chart_GenerateOddsData]
AS
/*
Created by: Dan
Date: 2013-05-27
Task: capture chart data for odds
DB: DB06/bodb_Chart
Revisions:

*/

SET NOCOUNT ON

declare @interval_nonlive_odds int
set @interval_nonlive_odds  = 15 -- minute 

DECLARE @now datetime
SET @now=getdate()

CREATE TABLE #temp(
	[oddsid] [int] NOT NULL,
	[Minute] [smallint] NOT NULL,
	[bettype] [smallint] NULL,
	[hdp1] [float] NULL,
	[hdp2] [float] NULL,
	[odds1a] [float] NULL,
	[odds2a] [float] NULL,
	[com1] [float] NULL,
	[comx] [float] NULL,
	[com2] [float] NULL,
	[oddsstatus] nvarchar(50)
	)

--capture live odds
INSERT INTO #temp(oddsid,bettype, hdp1, hdp2,odds1a,odds2a, com1,comx, com2,[Minute],oddsstatus )
select oddsid,bettype, hdp1, hdp2,
	case when odds1a < 0 then - 1.00/odds1a else odds1a end as odds1a,
	case when odds2a < 0 then - 1.00/odds2a else odds2a end as odds2a, 
	com1,comx, com2, mins,oddsstatus
from bodb02.dbo.odds (nolock) o join 
	(select matchid, datediff(mi, kickofftime, @now) as mins
		from [dbo].[match_queue] (nolock)
	)m on o.matchid=m.matchid
where bettype in (1,5,3)		
	and liveindicator=1	 
--	and oddsstatus='running'

--capture non-live odds
INSERT INTO #temp(oddsid,bettype, hdp1, hdp2,odds1a,odds2a, com1,comx, com2,[Minute],oddsstatus )
select oddsid,bettype, hdp1, hdp2, 
	case when odds1a < 0 then - 1.00/odds1a else odds1a end as odds1a,
	case when odds2a < 0 then - 1.00/odds2a else odds2a end as odds2a, 
	com1,comx, com2, mins,oddsstatus 
from bodb02.dbo.odds (nolock) o join 
	(select matchid, datediff(mi, kickofftime, @now) as mins
		from [dbo].[match_queue] (nolock)
		where datediff(mi, kickofftime, @now)%@interval_nonlive_odds = 0
	)m on o.matchid=m.matchid 
where bettype in (1,5,3)		
	and liveindicator=0	
--	and oddsstatus='running'

--INSERT ODDS DATA
INSERT INTO [dbo].[odds_trans](	
      [oddsid]
      ,[Minute]
      ,[bettype]
      ,[hdp1]
      ,[hdp2]
      ,[odds1a]
      ,[odds2a]
      ,[com1]
      ,[comx]
      ,[com2]
      ,[recordtime]
	)
SELECT [oddsid]
      ,[Minute]
      ,[bettype]
      ,[hdp1]
      ,[hdp2]
      ,[odds1a]
      ,[odds2a]
      ,[com1]
      ,[comx]
      ,[com2]
      ,@now
FROM #temp
WHERE NOT EXISTS(SELECT * FROM [dbo].[odds_trans] o (NOLOCK) 
				WHERE o.[oddsid]=#temp.[oddsid] and o.[Minute]=#temp.[Minute]) and oddsstatus='running'

--update odds table
UPDATE dbo.odds set hdp1=t.hdp1,hdp2=t.hdp2 from #temp as t
	where dbo.odds.oddsid=t.oddsid

--update setting
UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = convert(varchar(200), @now , 120)
WHERE VName = 'syncChart_Odds_MaxTransdate' 


DROP TABLE #temp 
GO


