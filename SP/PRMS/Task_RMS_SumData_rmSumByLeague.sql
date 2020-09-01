/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SumData_rmSumByLeague]
	@winlostdate	SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data of rmSumByLeague

	Revisions:
		- 20200601@Percy: Initialize SP [RedmineID: #130275]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @WLDate DATE
	SELECT  @WLDate = @winlostdate
	
	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	SELECT  @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @MBBU

	IF @winlostdate < @BalanceUpDay
		RETURN

	CREATE TABLE #rmSumByLeague
	(
		leagueId			INT
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
	CREATE CLUSTERED INDEX CIX_rmSumByLeague ON #rmSumByLeague (leagueId, ParlayType)

	DECLARE @bettrans TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @bettransByBatch TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @batch INT = 300000, @isBreak BIT

	CREATE TABLE #bettransmbk (refno BIGINT, statusID TINYINT, leagueid INT)
	DECLARE @bettransmByBatch TABLE (refno BIGINT, statusID TINYINT, leagueid INT)
	DECLARE @SQL VARCHAR(MAX)

	IF @winlostdate > @MoveBetsDay
	BEGIN
		INSERT INTO @bettrans (refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake*actualrate, (winlost-actual_stake)*actualrate, playercomm*actualrate, (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
		FROM dbo.rmBettrans r WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON r.recommend = c.custid
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		WHERE r.winlostdate = @winlostdate
			AND r.bettype = 29
			AND r.liveawayscore IN (1, 3) -- soccer
			AND r.statusID IN (111, 112, 113, 101, 102)
			AND r.currency <> 20
	END
	ELSE
	BEGIN
		INSERT INTO @bettrans (refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake*actualrate, (winlost-actual_stake)*actualrate, playercomm*actualrate, (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
		FROM dbo.rmBettrans_Old r WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON r.recommend = c.custid
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		WHERE r.winlostdate = @winlostdate
			AND r.bettype = 29
			AND r.liveawayscore IN (1, 3) -- soccer
			AND r.statusID IN (111, 112, 113, 101, 102)
			AND r.currency <> 20

		IF @winlostdate <= DATEADD(DAY, 7, @BalanceUpDay)
		BEGIN
			SET @SQL = 'SELECT refno, statusID, leagueid
						FROM OPENQUERY(DBARC, ''SELECT b.refno, bm.statusID, m.leagueid
												FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
													INNER JOIN bodb_Archive.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
													INNER JOIN bodb_Archive.dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
												WHERE b.winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''''
													AND b.bettype = 29
													AND b.currency <> 20
													AND b.liveawayscore IN (1, 3) -- soccer
													AND b.statusID IN (111, 112, 113, 101, 102)
													AND b.currency <> 20
													AND m.sporttype = 1'')'
			INSERT INTO #bettransmbk
			EXEC (@SQL)
		END
	END

	WHILE 1 = 1
	BEGIN
		DELETE @bettransByBatch
		DELETE @bettransmByBatch
		SET @isBreak = 0

		DELETE TOP (@batch) FROM @bettrans
			OUTPUT DELETED.refno, DELETED.ParlayType, DELETED.IsDeposit, DELETED.statusID, DELETED.stake, DELETED.winloss, DELETED.playercomm, DELETED.HouseWinloss
			INTO @bettransByBatch (refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)

		IF @@ROWCOUNT < @batch
			SET @isBreak = 1

		DELETE bm
			OUTPUT DELETED.refno, DELETED.statusID, DELETED.leagueid
			INTO @bettransmByBatch (refno, statusID, leagueid)
		FROM #bettransmbk bm
			INNER JOIN @bettransByBatch b ON bm.refno = b.refno

		INSERT INTO #rmSumByLeague
		SELECT
			t.leagueid
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
			,MainWinloss		= SUM(CASE WHEN t.rn = 1 THEN b.winloss ELSE 0 END)
			,MainComm			= SUM(CASE WHEN t.rn = 1 THEN b.playercomm ELSE 0 END)
			,MainHouseWinloss	= SUM(CASE WHEN t.rn = 1 THEN b.HouseWinloss ELSE 0 END)
		FROM @bettransByBatch b
			CROSS APPLY (
				SELECT leagueid, statusID, ROW_NUMBER() OVER(PARTITION BY leagueid ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT
						m.leagueid, bm.statusID
					FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT m.leagueid, bm.statusID
					FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT bm.leagueid, bm.statusID
					FROM @bettransmByBatch bm
					WHERE b.refno = bm.refno
				) bm
			) t
		GROUP BY
			t.leagueid
			,b.ParlayType
			,b.IsDeposit

		IF @isBreak = 1
			BREAK
	END

	BEGIN TRY
		DELETE dbo.rmSumByLeague WITH (ROWLOCK, UPDLOCK) WHERE winlostdate = @WLDate

		INSERT INTO dbo.rmSumByLeague (winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
		SELECT @WLDate,leagueId,ParlayType,IsDeposit,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
		FROM #rmSumByLeague
		GROUP BY leagueId,ParlayType,IsDeposit
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		--RETURN
	END CATCH

	DROP TABLE #bettransmbk
	DROP TABLE #rmSumByLeague
END
GO