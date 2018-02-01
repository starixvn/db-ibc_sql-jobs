USE [bodb_LCC]
GO

ALTER PROCEDURE [dbo].[Task_Event_UpdateMatchEvents]
AS
/*
Created by: Phuong
Date: 2013-07-11
Task: Update match events: score, HT...

Revisions:
	- 2013/12/12: Update disallowed events - Ricky
	- 2016-09-12@Patrick: Fix issue Arithmetic overflow error for data type tinyint
	- 20180201@Patrick: Move userlog_p table to LogDB database

*/


SET NOCOUNT ON
--CAST('2013-08-14 15:50:11.323' AS DATETIME)
DECLARE @now DATETIME
SET @now = GETDATE()

--UPDATE KICK OFF TIME BASE ON LIVE TIMER OF 1ST HALF
UPDATE match_queue 
SET kickofftime = mr.LiveTimer
FROM	(SELECT matchid,LiveTimer 
		FROM bodb02.dbo.match_remark 
		WHERE matchid IN 
			(SELECT matchid 
			FROM match_queue 
			WHERE liveperiod=0) AND LivePeriod=1) mr
WHERE match_queue.matchid=mr.matchid

/*UPDATE MATCH SCORE && STATUS*/
CREATE TABLE #scoreChanges(
	[matchid]		INT NOT NULL,
	[homeid]		INT NOT NULL,
	[awayid]		INT NOT NULL,
	[homescore]		SMALLINT NOT NULL,--Current home/away score
	[awayscore]		SMALLINT NOT NULL,
	[chartHomeScore]SMALLINT NOT NULL,--Chart Home/Away Score
	[chartAwayScore]SMALLINT NOT NULL,
	[homegoals]		SMALLINT NOT NULL,--Home/away score gap between sportbook data & chart data
	[awaygoals]		SMALLINT NOT NULL,
	[matchstatus]	VARCHAR(50) NOT NULL,
	[minute]		SMALLINT NOT NULL,
	[homeredcard]	INT NOT NULL,
	[awayredcard]	INT NOT NULL,
	[charthomeredcard]	TINYINT NOT NULL,
	[chartawayredcard]	TINYINT NOT NULL,
	[homediffredcard]	SMALLINT NOT NULL,
	[awaydiffredcard]	SMALLINT NOT NULL,
	[liveperiod]	TINYINT NOT NULL,
	[hthomescore]	SMALLINT NULL,--FIRST HALF SCORE
	[htawayscore]	SMALLINT NULL,
	[isHTCal]		BIT NOT NULL,
	[livetimer]		DATETIME NOT NULL,
	[confirmHT]		INT NOT NULL,
	[confirmFT]		INT NOT NULL
	)
	
INSERT INTO #scoreChanges([matchid],[homeid],[awayid],[homescore],[awayscore],[chartHomeScore],[chartAwayScore],
		[homegoals],[awaygoals], [matchstatus],[minute],[homeredcard],[awayredcard],[charthomeredcard],[chartawayredcard],[homediffredcard],[awaydiffredcard],
		[liveperiod],[hthomescore],[htawayscore], [isHTCal],[livetimer],[confirmHT],[confirmFT])
	
SELECT	m.matchid,m.homeid,m.awayid, 
		ISNULL(CASE m.eventstatus WHEN 'running' THEN m.livehomescore ELSE m.finalhomescore END,0),
		ISNULL(CASE m.eventstatus WHEN 'running' THEN m.liveawayscore ELSE m.finalawayscore END,0), 
		mq.homescore,
		mq.awayscore,
		ISNULL(CASE m.eventstatus WHEN 'running' THEN m.livehomescore ELSE m.finalhomescore END,0)-mq.homescore, 
		ISNULL(CASE m.eventstatus WHEN 'running' THEN m.liveawayscore ELSE m.finalawayscore END,0)-mq.awayscore,
		m.eventstatus,
		DATEDIFF(mi, mq.kickofftime, @now),
		ISNULL(mr.homeredcard,0),
		ISNULL(mr.awayredcard,0),
		mq.homeredcard,
		mq.awayredcard,
		CAST(mr.homeredcard AS SMALLINT) - mq.homeredcard,
		CAST(mr.awayredcard AS SMALLINT) - mq.awayredcard,
		ISNULL(mr.liveperiod,0),
		m.hthomescore,
		m.htawayscore,
		mr.IsHTCal,
		mr.LiveTimer,
		mr.confirmHT,
		mr.confirmFT
FROM bodb02.dbo.match m(nolock)
	INNER JOIN match_queue mq on m.matchid=mq.matchid and m.eventstatus in ('running','completed')
	INNER JOIN bodb02.dbo.match_remark mr(nolock) on m.matchid=mr.matchid

-- START INSERT EVENTS
-- GOAL EVENTS INCREASE
WHILE(EXISTS(SELECT * FROM #scoreChanges WHERE homegoals > 0 OR awaygoals > 0))
	BEGIN
		INSERT INTO [event](matchid,teamid,eventtype,value,[minute])
			SELECT matchid, homeid, 100, CAST(homegoals AS VARCHAR(50)), [minute]
			FROM #scoreChanges WHERE homegoals > 0
		UNION ALL
			SELECT matchid, awayid, 100, CAST(awaygoals AS VARCHAR(50)), [minute]
			FROM #scoreChanges WHERE awaygoals > 0

		UPDATE #scoreChanges
		SET homegoals = homegoals - 1
		WHERE homegoals > 0

		UPDATE #scoreChanges
		SET awaygoals = awaygoals - 1
		WHERE awaygoals > 0
	END
-- GOAL EVENTS DECREASE
DECLARE @matchId INT, 
		@homeScore SMALLINT, 
		@awayScore SMALLINT, 
		@chartHomeScore SMALLINT, 
		@chartAwayScore SMALLINT,
		@homeId INT,
		@awayId INT
WHILE(EXISTS(SELECT * FROM #scoreChanges WHERE homegoals < 0 OR awaygoals < 0))
	BEGIN
		SELECT TOP 1 @matchId = matchid, @homeScore = homescore, @chartHomeScore = chartHomeScore, 
					@chartAwayScore = chartAwayScore, @awayScore = awayscore, @homeId = homeid, @awayId = awayid
		FROM #scoreChanges
		WHERE homegoals < 0 OR awaygoals <0

		-- REMOVE HOME GOALS
		IF(@homeScore < @chartHomeScore)
		BEGIN
			DELETE 
			FROM [event]
			WHERE [eventid] IN (SELECT TOP (@chartHomeScore - @homeScore) [eventid]
								FROM [event]
								WHERE matchid = @matchId AND eventtype = 100 AND teamid = @homeId
								ORDER BY [eventid] DESC)
			--UPDATE GAP SCORE
			UPDATE #scoreChanges SET homegoals = 0 WHERE matchid = @matchId
		END
		
		-- REMOVE HOME GOALS
		IF(@awayScore < @chartAwayScore)
		BEGIN
			DELETE 
			FROM [event]
			WHERE [eventid] IN (SELECT TOP (@chartAwayScore - @awayScore) [eventid]
								FROM [event]
								WHERE matchid = @matchId AND eventtype = 100 AND teamid = @awayId
								ORDER BY [eventid] DESC)
			--UPDATE GAP SCORE
			UPDATE #scoreChanges SET awaygoals = 0 WHERE matchid = @matchId
		END
	END

-- RED CARDS EVENTS INCREASE
WHILE(EXISTS(SELECT * FROM #scoreChanges WHERE homediffredcard > 0 OR awaydiffredcard > 0))
	BEGIN
		INSERT INTO [event](matchid,teamid,eventtype,value,[minute])
			SELECT matchid, homeid, 102, CAST(homediffredcard AS VARCHAR(50)), [minute]
			FROM #scoreChanges WHERE homediffredcard > 0
		UNION ALL
			SELECT matchid, awayid, 102, CAST(awaydiffredcard AS VARCHAR(50)), [minute]
			FROM #scoreChanges WHERE awaydiffredcard > 0

		UPDATE #scoreChanges
		SET homediffredcard = homediffredcard - 1
		WHERE homediffredcard > 0

		UPDATE #scoreChanges
		SET awaydiffredcard = awaydiffredcard - 1
		WHERE awaydiffredcard > 0
	END
-- RED CARDS EVENTS DECREASE
DECLARE @homeRedCard TINYINT, 
		@awayRedCard TINYINT, 
		@chartHomeRedCard TINYINT, 
		@chartAwayRedCard TINYINT
WHILE(EXISTS(SELECT * FROM #scoreChanges WHERE homediffredcard < 0 OR awaydiffredcard < 0))
	BEGIN
		SELECT TOP 1 @matchId = matchid, @homeRedCard = homeredcard, @chartHomeRedCard = charthomeredcard, 
					@chartAwayRedCard = chartawayredcard, @awayRedCard = awayredcard, @homeId = homeid, @awayId = awayid
		FROM #scoreChanges
		WHERE homediffredcard < 0 OR awaydiffredcard <0

		-- REMOVE HOME RED CARDS
		IF(@homeRedCard < @chartHomeRedCard)
		BEGIN
			DELETE 
			FROM [event]
			WHERE [eventid] IN (SELECT TOP (@chartHomeRedCard - @homeRedCard) [eventid]
								FROM [event]
								WHERE matchid = @matchId AND eventtype = 102 AND teamid = @homeId
								ORDER BY [eventid] DESC)
			--UPDATE GAP RED CARDS
			UPDATE #scoreChanges SET homediffredcard = 0 WHERE matchid = @matchId
		END
		
		-- REMOVE AWAY RED CARDS
		IF(@awayRedCard < @chartAwayRedCard)
		BEGIN
			DELETE 
			FROM [event]
			WHERE [eventid] IN (SELECT TOP (@chartAwayRedCard - @awayRedCard) [eventid]
								FROM [event]
								WHERE matchid = @matchId AND eventtype = 102 AND teamid = @awayId
								ORDER BY [eventid] DESC)
			--UPDATE GAP RED CARDS
			UPDATE #scoreChanges SET awaydiffredcard = 0 WHERE matchid = @matchId
		END
	END

INSERT INTO [event](matchid,teamid,eventtype,value,[minute])
--1st HALF, HT, 2nd HALF
	SELECT m.matchid,0,201,'1H',[minute]
	FROM #scoreChanges m INNER JOIN match_queue AS mq (NOLOCK) ON m.matchid=mq.matchid
	WHERE mq.liveperiod=0 AND m.liveperiod=1
	UNION ALL
	SELECT m.matchid,0,203,'2H',DATEDIFF(mi, mq.kickofftime, m.livetimer)
	FROM #scoreChanges m INNER JOIN match_queue AS mq (NOLOCK) ON m.matchid=mq.matchid
	WHERE mq.liveperiod<>2 AND m.liveperiod=2
	UNION ALL
	SELECT ht.matchid,0,202,'HT',DATEDIFF(mi, mq.kickofftime, ht.logdate)
	FROM (SELECT mq.matchid,ul.logdate 
	 FROM match_queue mq INNER JOIN DB06.LogDB.dbo.UserLog_P AS ul(NOLOCK) 
		ON ul.extend=mq.matchid
		AND mq.matchid NOT IN 
		(SELECT e.matchid FROM [event] AS e(NOLOCK) INNER JOIN match_queue AS mq (NOLOCK) ON e.matchid=mq.matchid AND e.eventtype=202)
		AND ul.doing LIKE 'update half-time%ON') ht INNER JOIN match_queue AS mq (NOLOCK) ON mq.matchid=ht.matchid
--Match over event, detect from match_remark.confirmFT		
	UNION ALL
	SELECT m.matchid, 0, 205, 'Over', [minute]
	FROM #scoreChanges m INNER JOIN match_queue AS mq(NOLOCK) ON m.matchid=mq.matchid
	WHERE m.confirmFT=1 AND mq.confirmFT=0 
	
UPDATE match_queue SET 
	match_queue.homescore=m.homescore,
	match_queue.awayscore=m.awayscore,
	match_queue.matchstatus=m.matchstatus,
	match_queue.homeredcard=m.homeredcard,
	match_queue.awayredcard=m.awayredcard,
	match_queue.liveperiod=m.liveperiod,
	match_queue.hthomescore=m.hthomescore,
	match_queue.htawayscore=m.htawayscore,
	match_queue.confirmHT=m.confirmHT,
	match_queue.confirmFT=m.confirmFT,
	match_queue.livetimer=m.livetimer
FROM #scoreChanges m
WHERE match_queue.matchid=m.matchid


DROP TABLE #scoreChanges