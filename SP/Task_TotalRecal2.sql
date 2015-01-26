USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_TotalRecal2]    Script Date: 01/26/2015 04:50:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_TotalRecal2]
AS
SET NOCOUNT ON

Declare @Total TABLE (oddsid int PRIMARY KEY, HomeTotal money, AwayTotal money)
Declare @match TABLE (matchid int PRIMARY KEY)

INSERT INTO @match SELECT matchid FROM match with (nolock) WHERE eventstatus = 'running'

Declare MatchCursor CURSOR FOR SELECT matchid FROM @match
Declare @matchid int

OPEN MatchCursor
FETCH NEXT FROM MatchCursor INTO @matchid

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO @Total
	SELECT 
		oddsid,
		SUM(case when betteam='h' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * b.virtualrate * (1-b.tpositiontaking)) else 0 end) homeTotal,
		SUM(case when betteam='a' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * b.virtualrate * (1-b.tpositiontaking)) else 0 end) awayTotal
	FROM bettrans b with (nolock)
		--INNER JOIN exchange e with (nolock) ON b.currency = e.exchangeid
	WHERE bettype in (1, 2, 3, 7, 8, 12, 20) AND matchid = @matchid
		AND [status] NOT IN ('VOID','REJECT') --AND ruben = 0
		--AND oddsid <> 0 and matchid = 83266
	GROUP BY oddsid

	UPDATE odds with (rowlock, updlock)
	SET hometotal = IsNull(t.HomeTotal, 0), awaytotal = IsNull(t.AwayTotal, 0)
	FROM odds FULL OUTER JOIN @Total t ON odds.oddsid = t.oddsid 
	WHERE odds.matchid = @matchid AND odds.bettype IN (1, 2, 3, 7, 8, 12, 20)

	DELETE FROM @Total
	-----------------------------------------
	FETCH NEXT FROM MatchCursor INTO @matchid
END

CLOSE MatchCursor
DEALLOCATE MatchCursor

SET NOCOUNT OFF

GO

GRANT EXECUTE ON [dbo].[Task_TotalRecal2] TO [bodbadmin] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_TotalRecal2] TO [vnteam] AS [dbo]
GO


