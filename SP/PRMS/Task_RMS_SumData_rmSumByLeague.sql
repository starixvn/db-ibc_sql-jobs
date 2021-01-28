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
		- 20210111@Danny: Enhance performance (get data from bettrans_bk) [RedmineID: #123157]
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

	CREATE TABLE #BettransmByLeague
	(
		transid				BIGINT 
		,leagueId			INT
		,statusID			TINYINT
		,stake				MONEY
		,winloss			MONEY
		,playercomm			MONEY
		,HouseWinloss		MONEY
		,ParlayType			TINYINT
		,IsDeposit			BIT
		,BetCount			INT
		,WonCount			INT
		,LoseCount			INT
		,DrawCount			INT
	)
	

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

	DECLARE @bettrans TABLE (transid BIGINT, refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	--DECLARE @bettransByBatch TABLE (refno BIGINT, ParlayType TINYINT, IsDeposit BIT, statusID TINYINT, stake MONEY, winloss MONEY, playercomm MONEY, HouseWinloss MONEY)
	--DECLARE @batch INT = 300000, @isBreak BIT

	CREATE TABLE #bettransmbk (refno BIGINT, statusID TINYINT, leagueid INT)
	

	--DECLARE @bettransmByBatch TABLE (refno BIGINT, statusID TINYINT, leagueid INT)
	DECLARE @SQL VARCHAR(MAX)

	IF @winlostdate > @MoveBetsDay
	BEGIN
		INSERT INTO @bettrans (transid, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT transid, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake*actualrate, (winlost-actual_stake)*actualrate, playercomm*actualrate, (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
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
		INSERT INTO @bettrans (transid, refno, ParlayType, IsDeposit, statusID, stake, winloss, playercomm, HouseWinloss)
		SELECT transid, refno, CASE WHEN betteam = N'1' THEN 2 ELSE 3 END, s.isDeposit, statusID, stake*actualrate, (winlost-actual_stake)*actualrate, playercomm*actualrate, (-(winlost-actual_stake)*(1-tpositiontaking-CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8)))-scomm+scomm*CAST(ISNULL(epositiontaking, 0) AS DECIMAL(9,8))/(1 - tpositiontaking))*actualrate
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

			DECLARE @__query NVARCHAR(MAX), @__sqlCmd NVARCHAR(MAX), @isByBettype BIT = 0
			SELECT  @__query = N''		
			SELECT	@__query = @__query + N'EXEC Task_RMS_ARC_rmBettrans_Old_byLeagueOrBettype_Sel @winlostdate, @isByBettype'
			SELECT	@__sqlCmd = N'EXECUTE DBARC.bodb_archive.dbo.sp_executesql @query, N''@winlostdate SMALLDATETIME, @isByBettype BIT'', @winlostdate, @isByBettype'

			INSERT INTO #bettransmbk (refno, statusID, leagueid)
			EXECUTE	sys.sp_executesql @__sqlCmd, N'@query NVARCHAR(MAX), @winlostdate SMALLDATETIME, @isByBettype BIT', @__query, @winlostdate, @isByBettype
			
			-- Create index
			CREATE CLUSTERED INDEX idx_#bettransmbk_refno ON #bettransmbk(refno)


			INSERT INTO #BettransmByLeague (transid, leagueId, statusID, stake, winloss, playercomm, HouseWinloss, ParlayType, IsDeposit, BetCount, WonCount, LoseCount, DrawCount  )
			SELECT
				b.transid, 
				bm.leagueid, 
				b.statusID, 
				MAX(b.stake), 
				MAX(b.winloss),
				MAX(b.playercomm), 
				MAX(b.HouseWinloss), 
				b.ParlayType, 
				b.IsDeposit, 
				SUM(1), 
				SUM(CASE WHEN bm.statusID = 112 THEN 1 ELSE 0 END),
				SUM(CASE WHEN bm.statusID = 113 THEN 1 ELSE 0 END),
				SUM(CASE WHEN bm.statusID = 111 THEN 1 ELSE 0 END)
			FROM @bettrans b
				INNER JOIN #bettransmbk bm WITH (NOLOCK) ON b.refno = bm.refno
			GROUP BY  b.transid, bm.leagueid, b.ParlayType, b.IsDeposit, b.statusID

		END
	END

	INSERT INTO #BettransmByLeague (transid, leagueId, statusID, stake, winloss, playercomm, HouseWinloss, ParlayType, IsDeposit, BetCount, WonCount, LoseCount, DrawCount )
	SELECT
		b.transid, 
		m.leagueid, 
		b.statusID, 
		MAX(b.stake), 
		MAX(b.winloss),
		MAX(b.playercomm), 
		MAX(b.HouseWinloss), 
		b.ParlayType, 
		b.IsDeposit, 
		SUM(1), 
		SUM(CASE WHEN bm.statusID = 112 THEN 1 ELSE 0 END),
		SUM(CASE WHEN bm.statusID = 113 THEN 1 ELSE 0 END),
		SUM(CASE WHEN bm.statusID = 111 THEN 1 ELSE 0 END)
	FROM @bettrans b
		INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE  m.sporttype = 1
	GROUP BY  b.transid, m.leagueid, b.ParlayType, b.IsDeposit, b.statusID


	INSERT INTO #BettransmByLeague (transid, leagueId, statusID, stake, winloss, playercomm, HouseWinloss, ParlayType, IsDeposit, BetCount, WonCount, LoseCount, DrawCount  )
	SELECT
		b.transid, 
		m.leagueid, 
		b.statusID, 
		MAX(b.stake), 
		MAX(b.winloss),
		MAX(b.playercomm), 
		MAX(b.HouseWinloss), 
		b.ParlayType, 
		b.IsDeposit, 
		SUM(1), 
		SUM(CASE WHEN bm.statusID = 112 THEN 1 ELSE 0 END),
		SUM(CASE WHEN bm.statusID = 113 THEN 1 ELSE 0 END),
		SUM(CASE WHEN bm.statusID = 111 THEN 1 ELSE 0 END)
	FROM @bettrans b
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE m.sporttype = 1
	GROUP BY  b.transid, m.leagueid, b.ParlayType, b.IsDeposit, b.statusID

	CREATE NONCLUSTERED INDEX idx_#BettransmByLeague ON #BettransmByLeague(leagueid, ParlayType, IsDeposit) INCLUDE (BetCount,WonCount, DrawCount,LoseCount )



	BEGIN TRY
	DELETE dbo.rmSumByLeague WITH (ROWLOCK, UPDLOCK) WHERE winlostdate = @WLDate

	INSERT INTO dbo.rmSumByLeague (winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
		SELECT	@WLDate winlostdate
			,b.leagueid
			,b.ParlayType
			,b.IsDeposit
			,BetCount			= SUM(b.BetCount)
			,WonCount			= SUM(WonCount)
			,DrawCount			= SUM(DrawCount)
			,LoseCount			= SUM(LoseCount)
			,MainBetCount		= COUNT(1)
			,MainWonCount		= SUM(CASE WHEN b.statusID = 112 THEN 1 ELSE 0 END)
			,MainLoseCount		= SUM(CASE WHEN b.statusID = 113 THEN 1 ELSE 0 END)
			,MainDrawCount		= SUM(CASE WHEN b.statusID = 111 THEN 1 ELSE 0 END)
			,MainStake			= SUM(stake)
			,MainTurnover		= SUM(CASE WHEN b.statusID IN (111, 112, 113) THEN b.stake ELSE 0 END)
			,MainTurnoverNoDraw	= SUM(CASE WHEN b.statusID IN (112, 113) THEN b.stake ELSE 0 END)
			,MainWinloss		= SUM(b.winloss)
			,MainComm			= SUM(b.playercomm)
			,MainHouseWinloss	= SUM(b.HouseWinloss)
		FROM 
		(
			SELECT	b.leagueid
					,b.ParlayType
					,b.IsDeposit
					,b.transid
					,b.statusID
					,BetCount			= SUM(BetCount)
					,WonCount			= SUM(WonCount)
					,DrawCount			= SUM(DrawCount)
					,LoseCount			= SUM(LoseCount)
					,stake = MAX(b.stake)
					,winloss = MAX(b.winloss)
					,playercomm = MAX(b.playercomm)
					,HouseWinloss = MAX(b.HouseWinloss) 
				
			FROM #BettransmByLeague b
			GROUP BY b.transid, b.leagueid, b.ParlayType, b.IsDeposit, b.statusID
		) b
		GROUP BY
			b.leagueid, b.ParlayType, b.IsDeposit

		
		
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		--RETURN
	END CATCH

	
	DROP TABLE #BettransmByLeague
	DROP TABLE #bettransmbk
	DROP TABLE #rmSumByLeague
END
