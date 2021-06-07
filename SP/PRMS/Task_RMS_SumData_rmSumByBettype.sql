/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SumData_rmSumByBettype]
	@winlostdate	SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data of rmSumByBettype

	Revisions:
		- 20200601@Percy: Initialize SP [RedmineID: #135326]
		- 20210111@Danny: Enhance performance (get data from bettrans_bk) [RedmineID: #123157]
		- 20210607@Danny: Move 'Saba789' to Credit Site  [RedmineID: #153874]
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

	CREATE TABLE #rmSumByBettype
	(
		bettype				SMALLINT
		,ParlayType			TINYINT
		,IsDeposit			BIT
		,leagueId			INT
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
	CREATE CLUSTERED INDEX CIX_rmSumByBettype ON #rmSumByBettype (bettype, ParlayType)

	DECLARE @bettrans TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @bettransByBatch TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @batch INT = 300000, @isBreak BIT

	CREATE TABLE #bettransmbk (refno BIGINT, bettype SMALLINT, statusID TINYINT, leagueid INT)
	DECLARE @bettransmbkByBatch TABLE (refno BIGINT, bettype SMALLINT, statusID TINYINT, leagueid INT)
	DECLARE @SQL VARCHAR(MAX)
	
	--DECLARE @bettype TABLE (bettype SMALLINT, ParlayType TINYINT, leagueid INT)

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

	END

	-- get data from backup range
	BEGIN
			
		DECLARE @__query NVARCHAR(MAX), @__sqlCmd NVARCHAR(MAX), @isByBettype BIT = 1
		SELECT  @__query = N''		
		SELECT	@__query = @__query + N'EXEC Task_RMS_ARC_rmBettrans_Old_byLeagueOrBettype_Sel @winlostdate, @isByBettype'
		SELECT	@__sqlCmd = N'EXECUTE DBARC.bodb_archive.dbo.sp_executesql @query, N''@winlostdate SMALLDATETIME, @isByBettype BIT'', @winlostdate, @isByBettype'

		INSERT INTO #bettransmbk (refno, bettype, statusID, leagueid)
		EXECUTE	sys.sp_executesql @__sqlCmd, N'@query NVARCHAR(MAX), @winlostdate SMALLDATETIME, @isByBettype BIT', @__query, @winlostdate, @isByBettype
	END

	WHILE 1 = 1
	BEGIN
		DELETE @bettransByBatch
		--DELETE @bettype
		DELETE @bettransmbkByBatch
		SET @isBreak = 0

		DELETE TOP (@batch) FROM @bettrans
			OUTPUT DELETED.refno, DELETED.ParlayType, DELETED.IsDeposit, DELETED.statusID, DELETED.stake, DELETED.winloss, DELETED.playercomm, DELETED.HouseWinloss
			INTO @bettransByBatch (refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)

		IF @@ROWCOUNT < @batch
			SET @isBreak = 1

		DELETE bm
			OUTPUT DELETED.refno, DELETED.bettype, DELETED.statusID, DELETED.leagueid
			INTO @bettransmbkByBatch (refno, bettype, statusID, leagueid)
		FROM #bettransmbk bm
			INNER JOIN @bettransByBatch b ON bm.refno = b.refno

		INSERT INTO #rmSumByBettype
		SELECT
			t.bettype
			,b.ParlayType
			,b.IsDeposit
			,t.LeagueId
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
				SELECT bettype, LeagueId, statusID, ROW_NUMBER() OVER(PARTITION BY bettype, LeagueId ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT bm.bettype, m.leagueid, bm.statusID
					FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT bm.bettype, m.leagueid, bm.statusID
					FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT bm.bettype, bm.leagueid, bm.statusID
					FROM @bettransmbkByBatch bm
					WHERE b.refno = bm.refno
				) bm
			) t
		GROUP BY
			t.bettype
			,b.ParlayType
			,b.IsDeposit
			,t.LeagueId

		-- Total
		INSERT INTO #rmSumByBettype
		SELECT
			t.bettype
			,b.ParlayType
			,b.IsDeposit
			,0
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
				SELECT bettype, statusID, ROW_NUMBER() OVER(PARTITION BY bettype ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT bm.bettype, bm.statusID
					FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT bm.bettype, bm.statusID
					FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype = 1

					UNION ALL
					SELECT bm.bettype, bm.statusID
					FROM @bettransmbkByBatch bm
					WHERE b.refno = bm.refno
				) bm
			) t
		GROUP BY
			t.bettype
			,b.ParlayType
			,b.IsDeposit

		IF @isBreak = 1
			BREAK
	END

	BEGIN TRY
		DELETE dbo.rmSumByBettype WITH (ROWLOCK, UPDLOCK) WHERE winlostdate = @WLDate

		INSERT INTO dbo.rmSumByBettype (winlostdate,bettype,ParlayType,IsDeposit,leagueId,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
		SELECT @WLDate,bettype,ParlayType,IsDeposit,leagueId,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
		FROM #rmSumByBettype
		GROUP BY bettype,ParlayType,IsDeposit,leagueId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		--RETURN
	END CATCH

	DROP TABLE #bettransmbk
	DROP TABLE #rmSumByBettype
END
GO