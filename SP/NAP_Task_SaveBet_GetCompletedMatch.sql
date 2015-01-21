USE [bodb_ACC]
GO

/****** Object:  StoredProcedure [dbo].[NAP_Task_SaveBet_GetCompletedMatch]    Script Date: 01/21/2015 01:31:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[NAP_Task_SaveBet_GetCompletedMatch]
AS

/*
	Created by: Dom
	Date:2014-05-05
	Task: Get Completed match.
	DB: DB06.BODB02
	
	Revisions:
*/

BEGIN
	
	
	DECLARE @movebetdate DATETIME,
			@CurentDate DATETIME
			
	select @CurentDate=CONVERT(varchar(10),getdate(),120)
			
	SELECT @movebetdate = max(eventdate) 
    FROM  bodb02.dbo.match14 WITH(NOLOCK)

	INSERT INTO MatchList(MatchID,EventDate,EventStatus,JobFinished,JobGenerated,SportType,LeagueID,MatchCode,HomeID,AwayID)
	SELECT MatchID,EventDate,EventStatus,0,0,sporttype,leagueid,MatchCode,HomeID,AwayID
	FROM bodb02.dbo.match WITH(NOLOCK)
	WHERE matchid NOT IN (select matchlist.MatchID from MatchList WITH(NOLOCK) WHERE match.eventdate BETWEEN @movebetdate AND GETDATE()) 
	--AND matchid IN(select Distinct matchID from bettrans WITH(NOLOCK))
	AND eventdate BETWEEN DATEADD(DD,-1,@CurentDate) AND @CurentDate
	AND eventstatus = 'completed'
	AND (sporttype < 99 OR sporttype IN (180,186))
	
END

GO


