USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Event_SyncBettrans]    Script Date: 01/19/2015 03:01:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Event_SyncBettrans]
AS
/*
Created by: Dan
Date: 2013-05-29
Task: sync tickets to bettrans in Chart DB
DB: DB06/bodb_Chart
Revisions:

*/
SET NOCOUNT ON

declare @transid_min bigint, @transid_max bigint 

SELECT @transid_min = CAST(ISNULL(VValue, 0) as bigint)
FROM dbo.Settings with (rowlock)
WHERE VName = 'syncBettrans'	
--print @transid_min

--for testing
--SELECT @transid_max = 4618621779

DECLARE @now datetime
SET @now=getdate()

IF NOT EXISTS (SELECT TOP 1 matchid FROM [dbo].[match_queue] WITH (NOLOCK))
	RETURN

SELECT @transid_max = isnull(max(transid),@transid_min)  FROM bodb02.dbo.bettrans WITH(NOLOCK)

--no new record
IF EXISTS(SELECT 1 FROM bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE matchid IN (SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK))
				AND bettype in (1,5,3)	
				AND transid>@transid_min and transid<=@transid_max)
BEGIN
	INSERT INTO bettrans([transid]
      ,[transdate]
      ,[oddsid]
      ,[hdp1]
      ,[hdp2]
      ,[odds]
      ,[betteam]
      ,[winlostdate]
      ,[matchid]
      ,[bettype]
		  )
	SELECT [transid]
      ,[transdate]
      ,[oddsid]
      ,[hdp1]
      ,[hdp2]
      ,[odds]
      ,[betteam]
      ,[winlostdate]
      ,[matchid]
      ,[bettype]      	 
	FROM bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE matchid IN (SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK))
		AND bettype in (1,5,3)	
		AND transid>@transid_min and transid<=@transid_max
END

--insert all previous tickets if a match has been added to monitor first time
IF (EXISTS(SELECT 1 FROM [dbo].[match_queue] WITH(NOLOCK) WHERE isPendingSyncTicket = 1))
BEGIN
	DECLARE @match table(matchid int)
	INSERT INTO @match(matchid)
	SELECT matchid FROM [dbo].[match_queue] WITH (NOLOCK)  WHERE isPendingSyncTicket = 1

	INSERT INTO bettrans([transid]
      ,[transdate]
      ,[oddsid]
      ,[hdp1]
      ,[hdp2]
      ,[odds]
      ,[betteam]
      ,[winlostdate]
      ,[matchid]
      ,[bettype]
		  )
	SELECT [transid]
      ,[transdate]
      ,[oddsid]
      ,[hdp1]
      ,[hdp2]
      ,[odds]
      ,[betteam]
      ,[winlostdate]
      ,[matchid]
      ,[bettype]      	 
	FROM bodb02.dbo.bettrans b WITH(NOLOCK)
	WHERE matchid IN (SELECT matchid FROM @match)
		AND bettype in (1,5,3)			
		AND transid<=@transid_max
		AND NOT EXISTS(SELECT * FROM bettrans b1 WITH (NOLOCK)
					WHERE b1.transid=b.transid)

	UPDATE [match_queue]
	SET isPendingSyncTicket=0
	FROM @match m
	WHERE m.matchid=[match_queue].matchid	
END

UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = CAST(CAST(@transid_max as bigint) as varchar(200))
WHERE VName = 'syncBettrans'	


GO


