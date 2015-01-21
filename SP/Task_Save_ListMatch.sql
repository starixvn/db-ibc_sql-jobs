USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_Save_ListMatch]    Script Date: 01/21/2015 00:20:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_Save_ListMatch]
AS
SET NOCOUNT ON

-- GET NEW MATCH
INSERT INTO dbo.Save_ListMatch (matchid, kickofftime, eventstatus)
SELECT matchid, kickofftime, eventstatus
FROM dbo.match with (nolock)
WHERE matchid NOT IN (SELECT matchid FROM dbo.Save_ListMatch with (nolock))


-- UPDATE MATCH STATUS
UPDATE dbo.Save_ListMatch
SET
	-- if KickOffTime Change (Delay), and already save deadball, clear flag (for re-save data)
	IsGameStart  = CASE WHEN m.kickofftime > s.kickofftime AND IsGameStart = 1 THEN 0 ELSE IsGameStart END,
	-- if game change from completed to something else (undo settlement), and already save live, clear flag
	IsGameFinish = CASE WHEN m.eventstatus <> N'completed' AND s.eventstatus = N'completed' THEN 0 ELSE IsGameFinish END,
	-- update data to current value
	kickofftime = m.kickofftime,
	eventstatus = m.eventstatus
FROM
	dbo.match m (nolock)
	INNER JOIN dbo.Save_ListMatch s ON m.matchid = s.matchid
WHERE
	m.kickofftime <> s.kickofftime OR m.eventstatus <> s.eventstatus

	
Declare @match TABLE (matchid int, IsGameFinish bit)
-- CHECK FOR GAME ALREADY START FOR 5 MINUTES AND NO FLAG
INSERT INTO @match
SELECT matchid, 0 FROM dbo.Save_ListMatch with (nolock)
WHERE CURRENT_TIMESTAMP > DATEADD(minute, 5, kickofftime) AND IsGameStart = 0

-- CHECK FOR GAME ALREADY FINISH AND NO FLAG
INSERT INTO @match
SELECT matchid, 1 FROM dbo.Save_ListMatch with (nolock)
WHERE eventstatus = N'completed' AND IsGameFinish = 0

-- Set Flag for ListMatch table
UPDATE dbo.Save_ListMatch SET IsGameStart  = 1 WHERE matchid IN (SELECT matchid FROM @match WHERE IsGameFinish = 0)
UPDATE dbo.Save_ListMatch SET IsGameFinish = 1 WHERE matchid IN (SELECT matchid FROM @match WHERE IsGameFinish = 1)

Declare @matchid int, @IsGameFinish bit, @EventDate smalldatetime
Declare @BT TABLE (bettype smallint, liveindicator bit)
Declare @cnt int


StartLoop:
	SELECT TOP 1 @matchid = m.matchid, @IsGameFinish = IsGameFinish, @EventDate = EventDate
	FROM @match m INNER JOIN dbo.match mm with (nolock)
	ON m.matchid = mm.matchid
	WHERE m.IsGameFinish = 1

	SELECT @cnt = @@ROWCOUNT
	IF @cnt = 0 GOTO EndLoop

	-- Check If got ticket on this match
	IF EXISTS(SELECT TOP 1 matchid FROM bettrans with (nolock) WHERE matchid = @matchid)
	BEGIN
		EXEC dbo.Save_GameInfo @matchid, @EventDate

		DELETE FROM @BT
		INSERT INTO @BT (bettype, liveindicator)
		SELECT distinct bettype, liveindicator
		FROM dbo.bettrans (nolock)
		WHERE matchid = @matchid --AND LiveIndicator = @IsGameFinish

		IF @IsGameFinish = 1
		BEGIN
		-- DB02 : [Admin_Settlement_1] also got INSERT for Save_Jobs
		-- alter there as well if something change in table structure

			INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
			SELECT @matchid, @IsGameFinish, 'SUM', 0, 0
			
			INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
			SELECT @matchid, b.liveindicator, 'TB', b.bettype, t.typenamee
			FROM @BT b INNER JOIN dbo.bettype t with (nolock) ON b.bettype = t.typeid
			WHERE b.bettype IN (1,3,7,8,20) AND b.liveindicator = 0

			INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
			SELECT @matchid, b.liveindicator, 'TB', b.bettype, t.typenamee
			FROM @BT b INNER JOIN dbo.bettype t with (nolock) ON b.bettype = t.typeid
			WHERE b.bettype IN (1,3,7,8,20) AND b.liveindicator = 1

			INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
			SELECT @matchid, b.liveindicator, 'Bets', 
				CASE 
				WHEN b.bettype BETWEEN 1201 AND 1204 THEN bettype - 1200
				ELSE b.bettype END bettype, t.typenamee
			FROM @BT b INNER JOIN dbo.bettype t with (nolock) ON b.bettype = t.typeid
			--WHERE b.bettype IN (1,2,3,7,8,20,5,15)

			INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
			SELECT @matchid, @IsGameFinish, 'END', 0, 0
		END

		/*
		INSERT INTO dbo.Save_Jobs (matchid, liveindicator, savetype, bettype, typename)
		SELECT @matchid, @IsGameFinish, 'Bets', b.bettype, t.typenamee
		FROM @BT b INNER JOIN dbo.bettype t with (nolock) ON b.bettype = t.typeid
		WHERE b.bettype IN (1,2,3,7,8,20,5,15)
		*/

	END

	DELETE FROM @match
	WHERE matchid = @matchid AND IsGameFinish = @IsGameFinish

	GOTO StartLoop
EndLoop:

GO

GRANT VIEW DEFINITION ON [dbo].[Task_Save_ListMatch] TO [vnteam] AS [dbo]
GO


