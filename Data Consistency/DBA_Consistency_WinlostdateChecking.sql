/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
	
	DECLARE @Yesterday	SMALLDATETIME 
		  , @Today		SMALLDATETIME
		  , @Checkdate	SMALLDATETIME
		
	SET @Yesterday = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
	SET @Today = CAST(GETDATE() AS DATE)
	SET @Checkdate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
	
	CREATE TABLE #tmpTicket (TransId BIGINT PRIMARY KEY)
	INSERT INTO #tmpTicket (TransId)
	SELECT DISTINCT s.TransId
	FROM dbo.StatementMovementHistory s WITH(NOLOCK)
	WHERE s.LogDate >= @Yesterday AND s.LogDate < @Today
		AND s.BetType NOT IN (10, 9, 29, 2799) -- outright, parlay

	--Remove ticket Cashout & currency (20, 72)
	DELETE t
	FROM #tmpTicket t
		INNER JOIN dbo.bettrans b WITH (NOLOCK) ON t.TransId = b.TransId
	WHERE 1 = CASE WHEN b.statusID IN (111, 112, 113) AND b.betdaqid = -2 THEN 1
			       WHEN b.currency IN (20,72) THEN 1 
				   ELSE 0 END

	--Return table
	SELECT TOP (100) s.TransId
	FROM dbo.StatementMovementHistory s WITH(NOLOCK) 
		INNER JOIN #tmpTicket t ON s.TransId = t.TransId
	WHERE s.LogDate >= @Checkdate
	GROUP BY s.TransId
	HAVING COUNT(s.TransId) >=2
	
	DROP TABLE #tmpTicket
END