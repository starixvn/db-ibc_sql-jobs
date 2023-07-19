/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_WinlostdateChecking]
AS
/*
	Created: 20230616@July
	Task: Check ticket data consistency - detect abnormal winlost date vs settlement time (Rule #59) 
	DB: DBBAH-bodb02

	Revisions: 
		- 20230616@July: Create new SP - [Redmine:#189723]
		- 20230714@July: Enhance rule detect tickets with wrong winlostdate movement. (Rule #59) - [Redmine:#190963]
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Yesterday	SMALLDATETIME 
		  , @Today		SMALLDATETIME
		  , @Checkdate	SMALLDATETIME
		
	SET @Yesterday = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
	SET @Today = CAST(GETDATE() AS DATE)
	SET @Checkdate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
	
	CREATE TABLE #tmpStatementMovementHistory 
	(	  TransId			BIGINT
		, MatchId			INT
		, WinlostDate		DATETIME
		, OldWinlostDate	DATETIME
		, Logdate			DATETIME
	)

	INSERT INTO #tmpStatementMovementHistory (TransId, MatchId, WinlostDate, OldWinlostDate, Logdate)
	SELECT s.TransId, MatchId, WinlostDate, OldWinlostDate, Logdate
	FROM dbo.StatementMovementHistory s WITH(NOLOCK) 
	WHERE s.LogDate >= @Checkdate
		AND s.BetType NOT IN (10, 9, 29, 2799) -- outright, parlay

	--Return table
	SELECT DISTINCT s.TransId
	FROM #tmpStatementMovementHistory s WITH(NOLOCK) 
		CROSS APPLY (
					SELECT t.TransId, t.MatchId
					FROM #tmpStatementMovementHistory t WITH(NOLOCK) 
					WHERE  s.TransId = t.TransId 
						AND t.LogDate >= @Yesterday AND t.LogDate < @Today
					)dt
		OUTER APPLY(
					SELECT m.sporttype
					FROM dbo.match m WITH(NOLOCK)
					WHERE dt.matchid =  m.matchid
				)m
	WHERE 1 = CASE WHEN s.WinlostDate < s.OldWinlostDate THEN 1
				   WHEN m.sporttype = 50 THEN 1
				   ELSE 0 END 
	GROUP BY s.TransId
	HAVING COUNT(s.TransId) >=2
	
	DROP TABLE #tmpStatementMovementHistory
END