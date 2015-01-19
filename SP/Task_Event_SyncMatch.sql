USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Event_SyncMatch]    Script Date: 01/19/2015 03:06:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Event_SyncMatch]
AS
/*
Created by: Dan
Date: 2013-05-27
Task: sync matches to Chart DB
DB: DB06/bodb_Chart
Revisions:

*/
SET NOCOUNT ON

declare @matchid_min int, @matchid_max int 

SELECT @matchid_min = CAST(ISNULL(VValue, 0) as int)
FROM dbo.Settings with (rowlock)
WHERE VName = 'syncMatches'	
--print @matchid_min

--for testing
--SELECT @matchid_max = 4618621779

DECLARE @now datetime
SET @now=getdate()

SELECT @matchid_max = isnull(max(matchid),@matchid_min)  FROM bodb02.dbo.match WITH(NOLOCK)

--no new record
IF EXISTS(SELECT 1 FROM bodb02.dbo.match WITH(NOLOCK)
		WHERE leagueid IN (SELECT leagueid FROM [dbo].[league] WITH (NOLOCK) WHERE isMonitored=1 )
						AND matchid>@matchid_min and matchid<=@matchid_max)
BEGIN
	insert into match_queue([matchid]
		  ,[leagueid]
		  ,[homeid]
		  ,[awayid]
		  ,[eventdate]      
		  ,[kickofftime]      
		  )
	select [matchid]
		  ,[leagueid]
		  ,[homeid]
		  ,[awayid]
		  ,[eventdate]
		  ,[kickofftime]      	 
	from BODB02.DBO.match (NOLOCK) 	
	WHERE leagueid IN (SELECT leagueid FROM [dbo].[league] WITH (NOLOCK) WHERE isMonitored=1)
			AND matchid>@matchid_min and matchid<=@matchid_max
			AND datediff(mi, kickofftime, getdate()) between -1440 and 120
			AND [matchid] NOT IN (SELECT matchid FROM match_queue WITH (NOLOCK))
END

UPDATE dbo.Settings with(rowlock, updlock)
SET VValue = CAST(CAST(@matchid_max as int) as varchar(200))
WHERE VName = 'syncMatches'	

GO


