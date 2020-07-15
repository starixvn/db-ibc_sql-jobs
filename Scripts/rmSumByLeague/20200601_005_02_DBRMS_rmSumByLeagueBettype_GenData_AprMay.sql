/*<info serverAlias="DBARC-bodb_Archive"></info>*/
USE bodb_Archive
GO

/*
	Created: 20200601@Percy
	DB: DBARC-bodb_Archive
	Task: Gen data for new tables rmSumByLeague, rmSumByBettype

	Date range: 2020-04-01 --> 2020-05-31
*/

CREATE TABLE #bettrans (winlostdate SMALLDATETIME, refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)

INSERT INTO #bettrans (winlostdate, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
SELECT winlostdate, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake, (winlost-actual_stake)*actualrate, playercomm*actualrate,(-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
FROM dbo.bettrans_bk r WITH (NOLOCK)
	INNER JOIN bodb02.dbo.vw_Customer c WITH (NOLOCK) ON r.recommend = c.custid
	INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
WHERE winlostdate BETWEEN '2020-04-01' AND '2020-04-30'
	AND bettype = 29
	AND liveawayscore IN (1, 3) -- soccer
	AND statusID IN (111, 112, 113, 101, 102)

INSERT INTO #bettrans (winlostdate, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
SELECT winlostdate, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake, (winlost-actual_stake)*actualrate, playercomm*actualrate,(-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
FROM dbo.bettrans_bk r WITH (NOLOCK)
	INNER JOIN bodb02.dbo.vw_Customer c WITH (NOLOCK) ON r.recommend = c.custid
	INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
WHERE winlostdate BETWEEN '2020-05-01' AND '2020-05-31'
	AND bettype = 29
	AND liveawayscore IN (1, 3) -- soccer
	AND statusID IN (111, 112, 113, 101, 102)

-- SELECT COUNT(1) FROM #bettrans

CREATE TABLE #rmSumByBettype
(
	winlostdate			SMALLDATETIME
	,bettype			SMALLINT
	,ParlayType			TINYINT
	,IsDeposit			BIT
	,leagueIds			VARCHAR(MAX)
	,BetCount			INT
	,WonCount			INT
	,LoseCount			INT
	,DrawCount			INT
	,MainBetCount		INT
	,MainWonCount		INT
	,MainLoseCount		INT
	,MainDrawCount		INT
	,MainStake			MONEY
	,MainTurnover		MONEY
	,MainTurnoverNoDraw	MONEY
	,MainMemberWinloss	MONEY
	,MainMemberComm		MONEY
	,MainHouseWinloss	MONEY
)
CREATE CLUSTERED INDEX CIX_rmSumByBettype ON #rmSumByBettype (winlostdate, bettype, ParlayType)

CREATE TABLE #rmSumByLeague
(
	winlostdate			SMALLDATETIME
	,leagueId			INT
	,ParlayType			TINYINT
	,IsDeposit			BIT
	,BetCount			INT
	,WonCount			INT
	,LoseCount			INT
	,DrawCount			INT
	,MainBetCount		INT
	,MainWonCount		INT
	,MainLoseCount		INT
	,MainDrawCount		INT
	,MainStake			MONEY
	,MainTurnover		MONEY
	,MainTurnoverNoDraw	MONEY
	,MainMemberWinloss	MONEY
	,MainMemberComm		MONEY
	,MainHouseWinloss	MONEY
)
CREATE CLUSTERED INDEX CIX_rmSumByLeague ON #rmSumByLeague (winlostdate, leagueId, ParlayType)



-- run by batch
DECLARE @bettransByBatch TABLE (winlostdate SMALLDATETIME, refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
DECLARE @batch INT = 5000, @isBreak BIT = 0

DECLARE @bettransmByBatch TABLE (refno BIGINT, leagueid INT, bettype SMALLINT, statusID TINYINT)

DECLARE @bettype TABLE (winlostdate SMALLDATETIME, bettype SMALLINT, ParlayType TINYINT, leagueid INT)

DECLARE @TotalCount INT
SELECT  @TotalCount = COUNT(1) FROM #bettrans

DECLARE @TotalBatch INT = @TotalCount / @batch + 1
DECLARE @i INT = 1

DECLARE @ErrMsg VARCHAR(1000)

WHILE 1=1
BEGIN
	SET @ErrMsg = 'START BATCH ' + CONVERT(VARCHAR(10), @i) + '/' + CONVERT(VARCHAR(10), @TotalBatch)
	RAISERROR (@ErrMsg, 0, 0) WITH NOWAIT

	SET @i = @i + 1

	DELETE @bettransByBatch
	DELETE @bettransmByBatch
	DELETE @bettype
	SET @isBreak = 0

	DELETE TOP (@batch) FROM #bettrans
		OUTPUT DELETED.*
		INTO @bettransByBatch

	IF @@ROWCOUNT < @batch
		SET @isBreak = 1

	INSERT INTO @bettransmByBatch
	SELECT b.refno, bm.leagueid, bm.bettype, bm.statusID
	FROM @bettransByBatch b
		CROSS APPLY (
			SELECT m.leagueid, bm.bettype, bm.statusID
				FROM dbo.bettransm bm WITH (NOLOCK)
					INNER JOIN dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
				WHERE b.refno = bm.refno
					AND m.sporttype = 1
		) bm

	-- sum by league
	BEGIN
		INSERT INTO #rmSumByLeague
		SELECT
			b.winlostdate
			,t.leagueid
			,b.ParlayType
			,b.IsDeposit
			,BetCount			= SUM(1)
			,WonCount			= SUM(CASE WHEN t.statusID = 112 THEN 1 ELSE 0 END)
			,LoseCount			= SUM(CASE WHEN t.statusID = 113 THEN 1 ELSE 0 END)
			,DrawCount			= SUM(CASE WHEN t.statusID = 111 THEN 1 ELSE 0 END)
			,MainBetCount		= SUM(CASE WHEN t.rn = 1 THEN 1 ELSE 0 END)
			,MainWonCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 112 THEN 1 ELSE 0 END)
			,MainLoseCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 113 THEN 1 ELSE 0 END)
			,MainDrawCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 111 THEN 1 ELSE 0 END)
			,MainStake			= SUM(CASE WHEN t.rn = 1 THEN b.stake ELSE 0 END)
			,MainTurnover		= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (111, 112, 113) THEN b.stake ELSE 0 END)
			,MainTurnoverNoDraw	= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (112, 113) THEN b.stake ELSE 0 END)
			,MainMemberWinloss		= SUM(CASE WHEN t.rn = 1 THEN b.winloss ELSE 0 END)
			,MainMemberComm			= SUM(CASE WHEN t.rn = 1 THEN b.playercomm ELSE 0 END)
			,MainHouseWinloss	= SUM(CASE WHEN t.rn = 1 THEN b.HouseWinloss ELSE 0 END)
		FROM @bettransByBatch b
			CROSS APPLY (
				SELECT leagueid, statusID, ROW_NUMBER() OVER(PARTITION BY leagueid ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT bm.leagueid, bm.statusID
					FROM @bettransmByBatch bm
					WHERE b.refno = bm.refno 
				) bm
			) t
		GROUP BY
			b.winlostdate
			,t.leagueid
			,b.ParlayType
			,b.IsDeposit
	END

	-- sum by bettype
	BEGIN
		INSERT INTO #rmSumByBettype
		SELECT
			b.winlostdate
			,t.bettype
			,b.ParlayType
			,b.IsDeposit
			,LeagueIds			= ''
			,BetCount			= SUM(1)
			,WonCount			= SUM(CASE WHEN t.statusID = 112 THEN 1 ELSE 0 END)
			,LoseCount			= SUM(CASE WHEN t.statusID = 113 THEN 1 ELSE 0 END)
			,DrawCount			= SUM(CASE WHEN t.statusID = 111 THEN 1 ELSE 0 END)
			,MainBetCount		= SUM(CASE WHEN t.rn = 1 THEN 1 ELSE 0 END)
			,MainWonCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 112 THEN 1 ELSE 0 END)
			,MainLoseCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 113 THEN 1 ELSE 0 END)
			,MainDrawCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 111 THEN 1 ELSE 0 END)
			,MainStake			= SUM(CASE WHEN t.rn = 1 THEN b.stake ELSE 0 END)
			,MainTurnover		= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (111, 112, 113) THEN b.stake ELSE 0 END)
			,MainTurnoverNoDraw	= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (112, 113) THEN b.stake ELSE 0 END)
			,MainMemberWinloss		= SUM(CASE WHEN t.rn = 1 THEN b.winloss ELSE 0 END)
			,MainMemberComm			= SUM(CASE WHEN t.rn = 1 THEN b.playercomm ELSE 0 END)
			,MainHouseWinloss	= SUM(CASE WHEN t.rn = 1 THEN b.HouseWinloss ELSE 0 END)
		FROM @bettransByBatch b
			CROSS APPLY (
				SELECT bettype, statusID, ROW_NUMBER() OVER(PARTITION BY bettype ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT bm.bettype, bm.statusID
					FROM @bettransmByBatch bm
					WHERE b.refno = bm.refno
				) bm
			) t
		GROUP BY
			b.winlostdate
			,t.bettype
			,b.ParlayType
			,b.IsDeposit

		-- Update leagueIds
		INSERT INTO @bettype
		SELECT b.winlostdate, bm.bettype, b.ParlayType, bm.leagueid
		FROM @bettransByBatch b
			CROSS APPLY (
				SELECT bm.leagueid, bm.bettype
				FROM @bettransmByBatch bm
				WHERE b.refno = bm.refno
			) bm
		GROUP BY b.winlostdate, bm.bettype, b.ParlayType, bm.leagueid
		
		;WITH CTE_Bettype AS
		(
			SELECT b.winlostdate, b.bettype, b.ParlayType, LeagueIds = STUFF((SELECT ',' + CONVERT(VARCHAR(20), b1.leagueId) FROM @bettype b1 WHERE b1.bettype = b.bettype AND b1.ParlayType = b.ParlayType AND b1.winlostdate = b.winlostdate FOR XML PATH('')), 1, 1, '')
			FROM @bettype b
			GROUP BY b.winlostdate, b.bettype, b.ParlayType
		)
		UPDATE r
		SET r.LeagueIds = b.LeagueIds
		FROM #rmSumByBettype r
			INNER JOIN CTE_Bettype b ON r.bettype = b.bettype AND r.ParlayType = b.ParlayType AND r.winlostdate = b.winlostdate
	END

	IF @isBreak = 1
		BREAK
END

DROP TABLE #bettrans

INSERT INTO dbo.rmSumByBettype_xtest (winlostdate,bettype,ParlayType,IsDeposit,leagueIds,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
SELECT winlostdate,bettype,ParlayType,IsDeposit,leagueIds,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
FROM #rmSumByBettype
GROUP BY winlostdate, bettype,ParlayType,IsDeposit,leagueIds

INSERT INTO dbo.rmSumByLeague_xtest (winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
SELECT winlostdate,leagueId,ParlayType,IsDeposit,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
FROM #rmSumByLeague
GROUP BY winlostdate, leagueId,ParlayType,IsDeposit

DROP TABLE #rmSumByBettype
DROP TABLE #rmSumByLeague
