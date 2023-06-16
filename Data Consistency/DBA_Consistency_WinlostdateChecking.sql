/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_WinlostdateChecking]
AS
/*
	Created: 20230616@July
	Task: Check ticket data consistency - detect abnormal winlost date vs settlement time (Rule #59) 
	DB: DBBAH-bodb02

	Revisions: 
		- 20230616@July: Create new SP - [Redmine:#189723]
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @yesterday	SMALLDATETIME 
		  , @today		SMALLDATETIME
		  , @checkdate	SMALLDATETIME
		
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	SET @today = CAST(GETDATE() AS DATE)
	SET @checkdate = CONVERT(DATE, DATEADD(DAY, -7, GETDATE()))
	
	DECLARE @tmBettypes TABLE (Bettype SMALLINT)
	INSERT INTO @tmBettypes (Bettype)
	SELECT	DISTINCT BetType
	FROM dbo.SportBettypeMatrix WITH(NOLOCK)
	WHERE ProductID = 1 --Sportbook
		AND BetType NOT IN (10, 9, 29) -- outright, parlay

	CREATE TABLE #tmpTicket (TransId BIGINT)
	INSERT INTO #tmpTicket (TransId)
	SELECT DISTINCT s.TransId
	FROM dbo.StatementMovementHistory s WITH(NOLOCK)
		INNER JOIN @tmBettypes m ON s.Bettype = m.BetType
	WHERE s.LogDate >= @yesterday AND s.LogDate < @today

	--Return table
	SELECT TOP (100) s.TransId
	FROM dbo.StatementMovementHistory s WITH(NOLOCK) 
		INNER JOIN #tmpTicket t ON s.TransId = t.TransId
	WHERE s.LogDate >= @checkdate
	GROUP BY s.TransId
	HAVING COUNT(s.TransId) >=2
	
	DROP TABLE #tmpTicket
END