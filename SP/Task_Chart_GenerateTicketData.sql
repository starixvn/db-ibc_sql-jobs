USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Chart_GenerateTicketData]    Script Date: 01/19/2015 02:55:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Chart_GenerateTicketData]
AS
/*
Created by: Dan
Date: 2013-05-27
Task: generate chart data for ticket
DB: DB06/bodb_Chart
Revisions:

*/
SET NOCOUNT ON

DECLARE @transid_min bigint, @transid_max bigint, @interval_nonlive_ticket int, @max_transdate datetime
SET @interval_nonlive_ticket  = 15 -- minute 

SELECT @transid_min = CAST(ISNULL(VValue, 0) as bigint)
FROM dbo.Settings with (rowlock)
WHERE VName = 'syncChart_Ticket'	
--print @transid_min

SELECT @transid_max = isnull(max(transid),@transid_min)  
FROM dbo.bettrans WITH(NOLOCK)

SELECT @max_transdate = transdate
FROM dbo.bettrans WITH(NOLOCK)
WHERE transid=@transid_max

--for testing
--SELECT @transid_max = 4618621779


--no new record
IF @transid_max <= @transid_min 
	RETURN

CREATE TABLE #temp(	
	[matchid] [int] NOT NULL,
	[oddsid] [int] NULL,
	[bettype] [smallint] NULL,
	[MinuteGroup] [smallint] NOT NULL,		
	[TotalTickets] [int] NULL,
	[homeTickets] [int] NULL,
	[awayTickets] [int] NULL,
	[drawTickets] [int] NULL,
	[Minute] [smallint] NULL
	--[islive] [bit] NULL
	)

IF @transid_min = 0
BEGIN
	--capture all tickets
	insert into #temp
	select m.matchid,oddsid, bettype 
		--,datediff(mi, kickofftime, transdate) [minute]
		, CASE WHEN datediff(mi, kickofftime, transdate)	>= 0 
					THEN datediff(mi, kickofftime, transdate)
					ELSE datediff(mi, kickofftime, transdate)/@interval_nonlive_ticket
					END AS  [minute]
		, COUNT(1) total 
		, SUM(case when bettype in (1,3) and betteam=N'h' then 1 			
				when bettype in (5) and betteam=N'1' then 1 
				else 0 
				end) home
		, SUM(case when bettype in (1,3) and betteam=N'a' then 1 			
				when bettype in (5) and betteam=N'2' then 1 
				else 0 
				end) away
		, SUM(case when bettype in (5) and betteam=N'X' then 1 
				else 0 
				end) draw		
		, NULL		
	from  bettrans b with (nolock) --, index(CIX_matchid_bettype))	
			JOIN [dbo].[match_queue] m (NOLOCK) on 	m.matchid=b.matchid
	--where bettype in (1,5,3)			 

	GROUP by m.matchid,oddsid, bettype, 
			CASE WHEN datediff(mi, kickofftime, transdate)	>= 0 THEN datediff(mi, kickofftime, transdate)
					ELSE datediff(mi, kickofftime, transdate)/@interval_nonlive_ticket END
END
ELSE
BEGIN
	--capture ticket
	INSERT INTO #temp
	SELECT m.matchid,oddsid, bettype
		--, datediff(mi, kickofftime, transdate) [minute]
		, CASE WHEN datediff(mi, kickofftime, transdate)	>= 0 
				THEN datediff(mi, kickofftime, transdate)
				ELSE datediff(mi, kickofftime, transdate)/@interval_nonlive_ticket END [minute]
		, COUNT(1) total 
		, SUM(case when bettype in (1,3) and betteam=N'h' then 1 			
				when bettype in (5) and betteam=N'1' then 1 
				else 0 
				end) home
		, SUM(case when bettype in (1,3) and betteam=N'a' then 1 			
				when bettype in (5) and betteam=N'2' then 1 
				else 0 
				end) away
		, SUM(case when bettype in (5) and betteam=N'X' then 1 
				else 0 
				end) draw
		, NULL
		--, CASE  WHEN DATEDIFF(mi, kickofftime, transdate)>=0 THEN 1 ELSE 0 END as isLive		
	FROM  bettrans b with (nolock) --, index(CIX_matchid_bettype)) 				
		JOIN [dbo].[match_queue] m (NOLOCK) on 	m.matchid=b.matchid
	WHERE --bettype in (1,5,3) and		 
		transid>@transid_min 
		and transid<=@transid_max 
	GROUP BY m.matchid,oddsid, bettype --, datediff(mi, kickofftime, transdate)	
		, CASE WHEN datediff(mi, kickofftime, transdate)	>= 0 THEN datediff(mi, kickofftime, transdate)
					ELSE datediff(mi, kickofftime, transdate)/@interval_nonlive_ticket 
					END 
END

--delete unneeded data 
DELETE FROM #temp
WHERE [MinuteGroup]> 120 OR 
	[MinuteGroup] < -96 -- capture by 15 mins (96 unit * 15 mins = 24h)

--calculate minute 
UPDATE #temp
SET [Minute] = case when [MinuteGroup]<0 then [MinuteGroup] * @interval_nonlive_ticket else [MinuteGroup] end 

-- generate/update chart data 

-- accumated ticket count
UPDATE T
SET 
	[TotalTickets]=t.[TotalTickets] + #temp.[TotalTickets],
	homeTickets=t.homeTickets + #temp.homeTickets,
	awayTickets=t.awayTickets + #temp.awayTickets,
	recordtime = GETDATE()
FROM [dbo].[ticket_trans] t WITH (NOLOCK) 
		JOIN #temp ON #temp.matchid= t.matchid AND #temp.oddsid= t.oddsid AND #temp.Minute= t.Minute

INSERT INTO [dbo].[ticket_trans]
           ([matchid]
           ,[Minute]
           ,[oddsid]
           ,[bettype]
           ,[TotalTickets]
           ,[homeTickets]
           ,[awayTickets]
           ,[drawTickets]
           --,[islive]
           ,[recordtime])
SELECT		
			#temp.[matchid]
           ,#temp.[Minute]
           ,#temp.[oddsid]
           ,#temp.[bettype]
           ,#temp.[TotalTickets]
           ,#temp.[homeTickets]
           ,#temp.[awayTickets]
           ,#temp.[drawTickets]
           --,case when [MinuteGroup] >= 0 then 1 else 0 end as isLive
           , GETDATE() as [recordtime]
FROM #temp 
	LEFT JOIN [dbo].[ticket_trans] t WITH (NOLOCK)  ON #temp.matchid= t.matchid AND #temp.oddsid= t.oddsid AND #temp.[Minute]= t.[Minute]
WHERE t.matchid IS NULL

--update setting for tracing
UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = CAST(CAST(@transid_max as bigint) as varchar(200))
WHERE VName = 'syncChart_Ticket'	

UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = convert(varchar(200), @max_transdate , 120)
WHERE VName = 'syncChart_Ticket_MaxTransdate'

drop table #temp 
GO


