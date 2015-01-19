USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_Event_MoveCompletedMatch]    Script Date: 01/19/2015 02:57:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Event_MoveCompletedMatch]
AS
/*
Created by: Dan
Date: 2013-05-27
Task: move completed matched frommatch queue to match table
DB: DB06/bodb_Chart
Revisions:
	+ 2013-07-11 Phuong: remove join to bodb02, base on newly added field: matchstatus
*/
SET NOCOUNT ON
DECLARE @max_transdate datetime

INSERT INTO MATCH(	
		[matchid]
      ,[leagueid]
      ,[homeid]
      ,[awayid]
      ,[eventdate]
      ,[kickofftime]
      ,[homescore]
      ,[awayscore]
      ,[hthomescore]
      ,[htawayscore]
      ,[homeredcard]
      ,[awayredcard]
      ,[chartshowingstatus])
SELECT [matchid]
      ,[leagueid]
      ,[homeid]
      ,[awayid]
      ,[eventdate]
      ,[kickofftime]
      ,[homescore]
      ,[awayscore]
      ,[hthomescore]
      ,[htawayscore]
      ,[homeredcard]
      ,[awayredcard]
      ,[chartshowingstatus]
FROM [dbo].[match_queue]  
where matchstatus='completed' or matchid not in (select matchid from bodb02.dbo.match(nolock))

DELETE [dbo].[match_queue]
WHERE matchstatus='completed' or matchid not in (select matchid from bodb02.dbo.match(nolock))

GO


