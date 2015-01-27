USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Save_GameInfo]    Script Date: 01/27/2015 04:32:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Save_GameInfo]
	@matchid int,
	@EventDate smalldatetime
AS
SET NOCOUNT ON
Declare @dbDate smalldatetime,
		@leagueid int

	SELECT @dbDate = EventDate
	FROM dbo.Save_Info_Match with (nolock)
	WHERE matchid = @matchid

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO dbo.Save_Info_Match (eventdate, matchid, leagueid, matchcode, home, away)
		SELECT m.eventdate, m.matchid, m.leagueid, m.matchcode, h.teamname, a.teamname
		FROM dbo.match m with (nolock)
			INNER JOIN dbo.team h with (nolock) ON m.homeid = h.teamid
			INNER JOIN dbo.team a with (nolock) ON m.awayid = a.teamid
		WHERE matchid = @matchid

		GOTO LeagueCheck
	END
	ELSE IF @dbDate <> @EventDate
	BEGIN
		UPDATE dbo.Save_Info_Match
		SET eventdate = @EventDate
		WHERE matchid = @matchid

		GOTO LeagueCheck
	END

GOTO SkipLeague

LeagueCheck:
	SELECT @leagueid = leagueid
	FROM dbo.Save_Info_Match with (nolock)
	WHERE matchid = @matchid

	IF NOT EXISTS(SELECT * FROM dbo.Save_Info_League with (nolock) WHERE leagueid = @leagueid AND eventdate = @EventDate)
		INSERT INTO dbo.Save_Info_League (eventdate, leagueid, sporttype, leaguename)
		SELECT @eventdate, leagueid, sporttype, leaguename
		FROM dbo.league with (nolock)
		WHERE leagueid = @leagueid

SkipLeague:
GO


