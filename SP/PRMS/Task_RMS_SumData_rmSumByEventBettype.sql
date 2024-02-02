/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_SumData_rmSumByEventBettype]
	@winlostdate	SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20231228@Cherry
	DB: DBRMS-bodb_RMS
	Task: RMS - Sum data of rmSumByEventBettype

	Revisions:
		- 20231228@Cherry: Initialize SP [RedmineID: #197684]

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

	CREATE TABLE #rmSumByEventBettype
	(
		bettype				SMALLINT
		,ParlayType			TINYINT
		,LeagueId			INT
		,MatchId			INT
		,Betteam			NVARCHAR(10)
		,IsDeposit			BIT
		,TransList			NVARCHAR(MAX)
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
	CREATE CLUSTERED INDEX CIX_rmSumByEventBettype ON #rmSumByEventBettype (bettype, ParlayType, LeagueId, MatchId, Betteam)

	DECLARE @bettrans TABLE (transid BIGINT, refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @bettransByBatch TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	DECLARE @batch INT = 300000, @isBreak BIT

	CREATE TABLE #bettransmbk (refno BIGINT, bettype SMALLINT, statusID TINYINT, leagueid INT)
	DECLARE @bettransmbkByBatch TABLE (refno BIGINT, bettype SMALLINT, statusID TINYINT, leagueid INT)
	DECLARE @SQL VARCHAR(MAX)

	IF @winlostdate > @MoveBetsDay
	BEGIN
		INSERT INTO @bettrans (transid, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT transid, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, CASE WHEN s.Site = 'Saba789' THEN 0 ELSE s.isDeposit END, statusID, stake*actualrate,
		(winlost-actual_stake)*actualrate, playercomm*actualrate, 
		CASE WHEN tpositiontaking = 1 THEN 0 ELSE (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate END
		FROM dbo.rmBettrans r WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON r.recommend = c.custid
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		WHERE r.winlostdate = @winlostdate
			AND r.bettype = 29
			AND r.liveawayscore IN (1,2, 3) -- soccer
			AND r.statusID IN (111, 112, 113, 101, 102)
			AND r.currency <> 20
	END
	ELSE
	BEGIN
		INSERT INTO @bettrans (transid, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT transid, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, CASE WHEN s.Site = 'Saba789' THEN 0 ELSE s.isDeposit END, 
		statusID, stake*actualrate, (winlost-actual_stake)*actualrate, playercomm*actualrate, 
		CASE WHEN tpositiontaking = 1 THEN 0 ELSE (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate END
		FROM dbo.rmBettrans_Old r WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON r.recommend = c.custid
			INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON c.site = s.site
		WHERE r.winlostdate = @winlostdate
			AND r.bettype = 29
			AND r.liveawayscore IN (1, 2, 3) -- soccer
			AND r.statusID IN (111, 112, 113, 101, 102)
			AND r.currency <> 20

	END

	BEGIN
		INSERT INTO #rmSumByEventBettype (bettype, ParlayType, LeagueId, MatchId, Betteam, IsDeposit, TransList, BetCount, WonCount, LoseCount, DrawCount, MainBetCount, MainWonCount, MainLoseCount, MainDrawCount, MainStake, MainTurnover, MainTurnoverNoDraw, MainMemberWinloss, MainMemberComm, MainHouseWinloss)
		SELECT
			t.bettype,
			b.ParlayType,
			t.LeagueId,
			t.matchid,
			t.betteam,
			b.IsDeposit,
			STUFF((SELECT  ',' + CAST(bt.transid AS VARCHAR(30))
					FROM @bettrans bt
					WHERE bt.ParlayType = b.ParlayType
						AND bt.IsDeposit = b.IsDeposit
						AND bt.statusID = 112
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)')  
					,1,1,'') TransList,
			BetCount			= SUM(1),
			WonCount			= SUM(CASE WHEN t.statusID = 112 THEN 1 ELSE 0 END),
			LoseCount			= SUM(CASE WHEN t.statusID = 113 THEN 1 ELSE 0 END),
			DrawCount			= SUM(CASE WHEN t.statusID = 111 THEN 1 ELSE 0 END),
			MainBetCount		= SUM(CASE WHEN t.rn = 1 THEN 1 ELSE 0 END),
			MainWonCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 112 THEN 1 ELSE 0 END),
			MainLoseCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 113 THEN 1 ELSE 0 END),
			MainDrawCount		= SUM(CASE WHEN t.rn = 1 AND b.statusID = 111 THEN 1 ELSE 0 END),
			MainStake			= SUM(CASE WHEN t.rn = 1 THEN b.stake ELSE 0 END),
			MainTurnover		= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (111, 112, 113) THEN b.stake ELSE 0 END),
			MainTurnoverNoDraw	= SUM(CASE WHEN t.rn = 1 AND b.statusID IN (112, 113) THEN b.stake ELSE 0 END),
			MainWinloss			= SUM(CASE WHEN t.rn = 1 THEN b.winloss ELSE 0 END),
			MainComm			= SUM(CASE WHEN t.rn = 1 THEN b.playercomm ELSE 0 END),
			MainHouseWinloss	= SUM(CASE WHEN t.rn = 1 THEN b.HouseWinloss ELSE 0 END)
		FROM @bettrans b
			CROSS APPLY (
				SELECT bettype, LeagueId, statusID, matchId, betteam, 			
					ROW_NUMBER() OVER(PARTITION BY bettype, LeagueId, matchId, betteam ORDER BY (SELECT NULL)) AS rn
				FROM (
					SELECT bm.bettype, m.leagueid, bm.statusID, bm.matchId, bm.betteam				
					FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype IN (1,2) AND bm.winlostdate > @MoveBetsDay

					UNION ALL
					SELECT bm.bettype, m.leagueid, bm.statusID, bm.matchId, bm.betteam	
					FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype IN (1,2) AND bm.winlostdate BETWEEN @BalanceUpDay AND  @MoveBetsDay

					UNION ALL
					SELECT bm.bettype, m.leagueid, bm.statusID, bm.matchId, bm.betteam				
					FROM dbo.rmBettransm_bk bm WITH (NOLOCK)
						INNER JOIN dbo.rmMatch_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
					WHERE b.refno = bm.refno
						AND m.sporttype IN (1,2) AND bm.winlostdate < @BalanceUpDay
				) bm
			) t
		GROUP BY
			t.bettype,
			b.ParlayType,
			b.IsDeposit,
			t.LeagueId,
			t.matchid,
			t.betteam
	END

	BEGIN TRY
		DELETE dbo.rmSumByEventBettype WITH (ROWLOCK, UPDLOCK) WHERE winlostdate = @WLDate

		INSERT INTO dbo.rmSumByEventBettype (winlostdate,bettype,ParlayType,leagueId,matchId,betteam,IsDeposit,TransList,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
		SELECT @WLDate,bettype,ParlayType,leagueId,matchId,betteam,IsDeposit,
			COMPRESS((SELECT TransList AS 'tl'
					FROM #rmSumByEventBettype bt
					WHERE bt.ParlayType = b.ParlayType
						AND bt.IsDeposit = b.IsDeposit
						AND bt.bettype = b.bettype
						AND bt.LeagueId = b.LeagueId
						AND bt.MatchId = b.MatchId
						AND bt.Betteam = b.Betteam
					FOR JSON PATH
					,INCLUDE_NULL_VALUES)) TransList,
			SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),
			SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),
			SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),
			SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
		FROM #rmSumByEventBettype b
		GROUP BY bettype,ParlayType,IsDeposit,leagueId,matchId,betteam,TransList
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
	END CATCH

	DROP TABLE #bettransmbk
	DROP TABLE #rmSumByEventBettype
END
GO