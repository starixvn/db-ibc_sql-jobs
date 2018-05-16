/*<info serverAlias="DBTP-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RNG_DataConsistency_Check] @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @ProductId INT

	, @ErrMessage VARCHAR(512) = '' OUTPUT
AS
/*
	Created: 20160518@Patrick
	Task: Check data between bettrans & bettransRNG for RNG Game (Run on DB06/DBTP)
	DB: DBTP.bodb02
	Revision:
		- 20160517@Patrick: VoidBridge Integration [Redmine: #57675]
		- 20160609@Helen: Remove case 6 from service to check ticket correctness - [Redmine: 58904]
		- 20170212@Patrick: Add more FW product
		- 20180417@Patrick: Update rule calculate winlost amount for contribution ticket
		- 20180419@Kathy: Update rule for RNG Jackpot [Redmine:#83787] 
		
*/
BEGIN
	SET @ErrMessage = ''

	CREATE TABLE #tempdata(custid INT, username VARCHAR(50), transid BIGINT, ProductID INT, gameid smallint
		, stake MONEY, actual_stake MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
		, playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
		, winlostdate SMALLDATETIME, status VARCHAR(10), issum bit, StatusID tinyint
		, ContributionStake3rd DECIMAL(19,8), BetStake MONEY, ContributionRate Decimal(9,8)
		,JackpotInfo VARCHAR(50), Additional VARCHAR(1000)
		,transdate DATETIME, refno2 BIGINT
	)
	
	DECLARE @sourcedata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		)

	DECLARE @targetdata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8))

	INSERT INTO #tempdata (custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID
		, ContributionStake3rd, BetStake, ContributionRate
		, JackpotInfo, Additional
		, transdate, refno2
	)
	SELECT custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID
		, ContributionStake3rd, BetStake, ContributionRate
		, JackpotInfo, Additional
		, transdate, RefNo2
	FROM dbo.bettransRnG WITH (NOLOCK)
	WHERE productID = @ProductId
		AND winlostdate BETWEEN @FromDate AND @ToDate

	INSERT INTO @sourcedata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount)
	SELECT custid, username, productid, gameID, winlostdate
		, CASE WHEN SUM(winlost-actual_stake) > 0 THEN 'WON'
			WHEN SUM(winlost-actual_stake) < 0 THEN 'LOSE'
		 ELSE 'DRAW' END AS STATUS
		, SUM(stake) AS stake, SUM(winlost - actual_stake) AS winlost, SUM(awinlost) AS awinlost
		, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost
		, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
		, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking
		, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
		, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
	FROM #tempdata
	WHERE issum = 1
	GROUP BY custid, username, productid, gameid, winlostdate

	INSERT INTO @targetdata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount)
	SELECT custid, username, matchid, bettype, winlostdate, status
		, SUM(stake) AS stake, SUM(winlost-actual_stake) AS winlost
		, SUM(awinlost) AS awinlost, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost
		, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
		, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
		, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = @ProductId
		AND winlostdate BETWEEN @fromdate AND @todate
		AND statusid NOT IN (0, 1, 131)
	GROUP BY custid, username, matchid, bettype, winlostdate, status
	
	SELECT TOP 1000 'Case 1' AS [CASE], s.*, t.*
	FROM @sourcedata s
		FULL OUTER JOIN @targetdata t 
			ON s.custid = t.custid 
				AND s.bettype = t.bettype 
				AND s.winlostdate = t.winlostdate
	WHERE ISNULL(s.turnover, 0) <> ISNULL(t.turnover, 0)
		OR ISNULL(s.winlost, 0) <> ISNULL(t.winlost, 0)
		OR ISNULL(s.swinlost, 0) <> ISNULL(t.swinlost, 0) 
		OR ISNULL(s.mwinlost, 0) <> ISNULL(t.mwinlost, 0) 
		OR ISNULL(s.awinlost, 0) <> ISNULL(t.awinlost, 0)
	
		OR ISNULL(s.scomm, 0) <> ISNULL(t.scomm, 0) 
		OR ISNULL(s.acomm, 0) <> ISNULL(t.acomm, 0) 
		OR ISNULL(s.comm, 0) <> ISNULL(t.comm, 0) 
		OR ISNULL(s.playercomm, 0) <> ISNULL(t.playercomm, 0)

		OR ISNULL(s.apositiontaking, 0) <> ISNULL(t.apositiontaking, 0)
		OR ISNULL(s.mpositiontaking, 0) <> ISNULL(t.mpositiontaking, 0)
		OR ISNULL(s.spositiontaking, 0) <> ISNULL(t.spositiontaking, 0)
		OR ISNULL(s.tpositiontaking, 0) <> ISNULL(t.tpositiontaking, 0)

		OR ISNULL(s.playerdiscount, 0) <> ISNULL(t.playerdiscount, 0)
		OR ISNULL(s.discount, 0) <> ISNULL(t.discount, 0)
		OR ISNULL(s.adiscount, 0) <> ISNULL(t.adiscount, 0)
		OR ISNULL(s.sdiscount, 0) <> ISNULL(t.sdiscount, 0)

		OR ISNULL(s.status, 0) <> ISNULL(t.status, 0)

	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 1: Check ticket details between bettrans AND bettransRNG.'
		RETURN
	END
	
	SELECT TOP 1000 'Case 2,3,4,5' AS [CASE]
		, t.*
		, CASE WHEN (winlost > actual_stake AND status <> 'WON') THEN 'Issue: Status should be WON'
				 WHEN (winlost = actual_stake AND status NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT')) THEN 'Issue: Status should be DRAW/REFUND/VOID/REJECT'
				 WHEN (winlost < actual_stake AND status <> 'LOSE') THEN 'Issue: Status should be LOSE'
				 WHEN (-(winlost - actual_stake) * apositiontaking <> awinlost) THEN 'Issue: awinlost is calculated wrongly' 
				 WHEN (-(winlost - actual_stake) * mpositiontaking <> mwinlost) THEN 'Issue: mwinlost is calculated wrongly' 
				 WHEN (-(winlost - actual_stake) * spositiontaking <> swinlost) THEN 'Issue: swinlost is calculated wrongly' 
				 WHEN (stake * playerdiscount <> playercomm) THEN 'Issue: playercomm is wrong'
				 WHEN (stake * discount * (1 - apositiontaking) <> comm) THEN 'Issue: comm is wrong'
				 WHEN (stake * adiscount * (1 - (mpositiontaking + apositiontaking)) <> acomm) THEN 'Issue: acomm is wrong'
				 WHEN (stake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) <> scomm) THEN 'Issue: scomm is wrong'
			END AS 'Comment'
	FROM #tempdata t
	WHERE StatusId NOT IN (0,1)
		AND ((winlost > actual_stake AND status <> 'WON')--Case 2: Check data in BettransRnG - if winlost - actual_stake > 0 -> status=WON
			OR (winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))--Case 3: Check data in BettransRnG - if winlost - actual_stake = 0 -> status=DRAW
			OR (winlost < actual_stake AND status <> 'LOSE')--Case 4: Check data in BettransRnG - if winlost - actual_stake < 0 -> status=LOSE
			
			OR (-(winlost - actual_stake) * apositiontaking <> awinlost) --Case 5: Check data in BettransRnG - awinlost, playercomm are calculated correctly
			OR (-(winlost - actual_stake) * mpositiontaking <> mwinlost)
			OR (-(winlost - actual_stake) * spositiontaking <> swinlost)
			
			OR (statusid IN (112,113) AND (CAST(stake * playerdiscount AS money) <> playercomm)) --Case 5b: playercomm is wrong
			OR (statusid IN (112,113) AND (CAST(stake * discount * (1 - apositiontaking) AS money) <> comm)) --Case 5c: comm is wrong
			OR (statusid IN (112,113) AND (CAST(stake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) --Case 5d: acomm is wrong		
			OR (statusid IN (112,113) AND (CAST(stake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)) --Case 5e: scomm is wrong
			)
		AND gameid NOT IN (2198, 2398, 2998, 2199, 2399, 2999)
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 2,3,4,5: Check status/awinlost/mwinlost/swinlost/playercomm/comm/acomm/scomm of tickets in bettransRNG.'
		RETURN
	END

	--for FW product: only one ticket running at the time
	IF @ProductId = 219
	BEGIN
		
		SELECT TOP 1000 'One member have greater than 1 running ticket at the time.' AS [CASE], custid
		FROM #tempdata
		WHERE StatusID = 0 AND gameid BETWEEN 1011 AND 1020
		GROUP BY custid, status
		HAVING COUNT(1) > 1

		IF @@ROWCOUNT > 0
		BEGIN
			SET @ErrMessage = @ErrMessage
				+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
				+ ' - Case: A member have two or more than 1 running ticket at the time.'
			RETURN
		END
	END

	IF @ProductId IN (208, 210)
	BEGIN
		--check contribution ticket
		BEGIN
			SELECT	TOP 1000 'Contribution ticket' AS [CASE]
					,CAST(CASE 					
						WHEN (-ROUND(ContributionStake3rd * apositiontaking, 4) <> awinlost) 
							OR (ContributionStake3rd IS NULL OR apositiontaking IS NULL OR awinlost IS NULL) THEN 'Issue: awinlost is calculated wrongly' 
						WHEN (-ROUND(ContributionStake3rd * mpositiontaking, 4) <> mwinlost)
							OR (ContributionStake3rd IS NULL OR mpositiontaking IS NULL OR mwinlost IS NULL) THEN 'Issue: mwinlost is calculated wrongly' 
						WHEN (-ROUND(ContributionStake3rd * spositiontaking, 4) <> swinlost)
							OR (ContributionStake3rd IS NULL OR spositiontaking IS NULL OR swinlost IS NULL) THEN 'Issue: swinlost is calculated wrongly' 
						WHEN (ROUND(ContributionStake3rd,4) <> ROUND(ContributionRate * BetStake, 4))
							OR (ContributionStake3rd IS NULL OR ContributionRate IS NULL OR BetStake IS NULL) THEN 'Issue: Incorrect ContributionStake3rd value'
						WHEN StatusID NOT IN (111, 103)
							OR StatusID IS NULL THEN 'Issue: The statusId must be DRAW or REFUND'
						WHEN (winlost + actual_stake + stake <> 0)
							OR (winlost IS NULL OR actual_stake IS NULL OR stake IS NULL) THEN 'Issue: The winlost, actual_stake, stake value must be zero'
						END AS VARCHAR(1000)) AS 'Comment'
					, t.*					
			INTO #Result1
			FROM	#tempdata t
			WHERE	gameid IN (2198, 2398, 2998) -- contribution bettypes
					AND (
							((- ROUND(ContributionStake3rd * apositiontaking, 4) <> awinlost)
								OR (ContributionStake3rd IS NULL OR apositiontaking IS NULL OR awinlost IS NULL))
							OR ((- ROUND(ContributionStake3rd * mpositiontaking, 4) <> mwinlost)
								OR (ContributionStake3rd IS NULL OR mpositiontaking IS NULL OR mwinlost IS NULL))
							OR ((-ROUND(ContributionStake3rd * spositiontaking, 4) <> swinlost)
								OR (ContributionStake3rd IS NULL OR spositiontaking IS NULL OR swinlost IS NULL))
							OR ((ROUND(ContributionStake3rd,4) <> ROUND(ContributionRate * betstake, 4))
								OR (ContributionStake3rd IS NULL OR ContributionRate IS NULL OR BetStake IS NULL))
							OR (StatusID NOT IN (111, 103)
								OR StatusID IS NULL)
							OR ((winlost + actual_stake + stake <> 0)
								OR (winlost IS NULL OR actual_stake IS NULL OR stake IS NULL))
						)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM #Result1

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Contribution ticket: Incorrect value of 1 of these columns: winlost/awinlost/swinlost/ContributionStake3rd/statusId/actual_Stake '

				DROP TABLE #Result1

				RETURN
			END
		END

		--check jackpot bet ticket
		BEGIN
			SELECT	TOP 1000 'Jackpot bet ticket' AS [CASE]
					, CAST(CASE 
						WHEN (StatusId <> 103 AND ContributionStake3rd <> ROUND(ContributionRate * actual_stake, 4) ) 
							OR (ContributionStake3rd IS NULL OR ContributionRate IS NULL OR actual_stake IS NULL)THEN 'Issue: ContributionStake3rd must be equal contributionRate * actual_stake' 
						END AS VARCHAR(1000)) AS 'Comment'
					, t.*					
			INTO #Result2
			FROM	#tempdata t
			WHERE	gameid IN (2179, 2320, 2920) -- jackpot bettypes
					AND (
							((StatusID <> 103 AND ContributionStake3rd <> ContributionRate * actual_stake)
							OR (ContributionStake3rd IS NULL OR ContributionRate IS NULL OR actual_stake IS NULL))
						)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM #Result2

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot bet ticket: Incorrect value of ContributionStake3rd'

				DROP TABLE #Result2

				RETURN
			END
		END

		-- check jackpot win ticket
		BEGIN
			-- win JP under max limit
			SELECT	TOP 1000 'Jackpot win ticket: under maxlimit' AS [CASE]
					, CAST(CASE 
						WHEN actual_stake <> 0 OR actual_stake IS NULL THEN 'Issue: Actual_Stake must be 0 for JP win ticket'
						WHEN (winlost <= actual_stake) OR winlost IS NULL OR actual_stake IS NULL THEN 'Issue: Winlost must be > actual_stake for JP win ticket'
						END AS VARCHAR(1000)) AS 'Comment'
					, t.*					
			INTO	#Result3
			FROM	#tempdata t
			WHERE	gameid IN (2199, 2399, 2999) -- jackpot win bettypes
					AND Additional like '%JPType=1%'
					AND (
							(actual_stake <> 0 OR actual_stake IS NULL)
							OR (winlost <= actual_stake OR winlost IS NULL OR actual_stake IS NULL)
						)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM	#Result3

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot win ticket (win JP under maxlimit): Actual_Stake must be 0, winlost > actual_stake for JP win ticket'

				DROP TABLE #Result3

				RETURN
			END
			
			-- deposit member win JP over max limit
			SELECT	TOP 1000 'Jackpot win ticket: member deposit win JP over max limit' AS [CASE]
					, CAST(CASE 
						WHEN winlost = 0 OR winlost IS NULL THEN 'Issue: winlost must be > 0 for JP win ticket'
						WHEN (actual_stake <> 0  OR actual_stake IS NULL) THEN 'Issue: actual_stake must be 0 for JP win ticket'
						END AS VARCHAR(1000)) AS 'Comment'
					, t.*
			INTO	#Result4
			FROM	#tempdata t
			WHERE	gameid IN (2199, 2399, 2999) -- jackpot win bettypes
					AND Additional like '%JPType=2%'
					AND (
							(winlost = 0 OR winlost IS NULL)
							OR (actual_stake <> 0  OR actual_stake IS NULL)
						)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT	*
				FROM	#Result4

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot win ticket (deposit member win JP over max limit): winlost must be >0, actual_stake must be 0 for JP win ticket'
				
				DROP TABLE #Result4

				RETURN
			END

			-- credit member win JP over max limit
			SELECT	TOP 1000 'Jackpot win ticket: member credit win JP over max limit' AS [CASE]
					, CAST(CASE 
						WHEN (winlost + actual_stake <> 0) OR winlost IS NULL OR actual_stake IS NULL THEN 'Issue: winlost/actual_stake must be 0 '
						WHEN (StatusID = 0 AND winlostdate <> DATEADD(MONTH, 3, CAST(transdate AS DATE))) OR StatusID IS NULL OR winlostdate IS NULL THEN 'Issue: winlostdate must be 3 months larger than transdate'
						END AS VARCHAR(1000)) AS 'Comment'
					, t.*					
			INTO	#Result5
			FROM	#tempdata t
			WHERE	gameid IN (2199, 2399, 2999) -- jackpot win bettypes
					AND Additional like '%JPType=3%'
					AND (
							((winlost + actual_stake <> 0) OR winlost IS NULL OR actual_stake IS NULL )
							OR ((StatusID = 0 AND winlostdate <> DATEADD(MONTH, 3, CAST(transdate AS DATE))) OR StatusID IS NULL OR winlostdate IS NULL)
						)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM	#Result5

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot win ticket (credit member win JP over max limit): winlost must be 0, actual_stake must be 0 for JP win ticket'

				DROP TABLE #Result5

				RETURN
			END
		END

		-- check all tickets
		BEGIN
			SELECT	TOP 1000 
					CAST(CASE
						WHEN gameid IN (2179, 2320, 2920) THEN 'Jackpot bet ticket'
						WHEN gameid IN (2198, 2398, 2998) THEN 'contribution ticket'
						WHEN gameid IN (2199, 2399, 2999) THEN 'Jackpot win ticket'
						END AS VARCHAR(100))
					AS [CASE]
					,CAST(CASE 
						WHEN (playercomm + comm + acomm + scomm  <> 0 )
							OR playercomm IS NULL OR COMM IS NULL OR acomm IS NULL OR scomm IS NULL THEN 'Issue: playercomm, comm, acomm, scomm must be 0'
						WHEN playerdiscount + discount + adiscount + sdiscount <> 0
							OR playerdiscount IS NULL OR discount IS NULL OR adiscount IS NULL OR sdiscount IS NULL THEN 'Issue: playerdiscount, discount, adiscount, sdiscount must be 0'
						WHEN (StatusID NOT IN (0, 103) AND ISNULL(refno2,0) = 0)
							OR StatusID IS NULL THEN 'Issue: refno2 value must be <> 0' 
						WHEN (StatusID = 103 AND (ContributionStake3rd <> 0 OR BetStake <> 0))
							OR StatusID IS NULL OR ContributionStake3rd IS NULL OR BetStake IS NULL THEN 'Issue: ContributionStake3rd and BetStake must be 0 when ticket was refunded'
						WHEN (StatusID <> 103 AND ContributionStake3rd = 0)
							OR StatusID IS NULL OR ContributionStake3rd IS NULL THEN 'Issue: ContributionStake3rd must be <> 0'	
					END AS VARCHAR(1000)) AS 'Comment'
					, t.*					
			INTO	#Result6
			FROM	#tempdata t
			WHERE	gameId IN (2179, 2320, 2920, 2198, 2398, 2998, 2199, 2399, 2999)
					AND (((playercomm + comm + acomm + scomm  <> 0) 
							OR playercomm IS NULL OR COMM IS NULL OR acomm IS NULL OR scomm IS NULL )
						OR (playerdiscount + discount + adiscount + sdiscount <> 0 OR playerdiscount IS NULL OR discount IS NULL OR adiscount IS NULL OR sdiscount IS NULL)
						OR ((StatusID NOT IN (0,103) AND ISNULL(refno2,0) = 0 ) OR StatusID IS NULL )
						OR ((StatusID = 103 AND (ContributionStake3rd <> 0 OR BetStake <> 0)) 
							OR StatusID IS NULL OR ContributionStake3rd IS NULL)
						OR ((StatusID <> 103 AND ContributionStake3rd = 0) OR StatusID IS NULL OR ContributionStake3rd IS NULL)
					)

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM	#Result6

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot bet/contribution/Jackpot win ticket: Incorrect value of 1 of these columns: commission/discount/refno2/contributionstake3rd'

				DROP TABLE #Result6

				RETURN
			END
		END

		-- contribution, jackpot bet
		BEGIN
			SELECT	TOP 1000 'Contribution - Jackpot bet ticket' AS [CASE]
					, CAST(CASE 
						WHEN (contri.StatusID <> 103 AND contri.BetStake <> jpbet.actual_stake) THEN 'Issue: contribution.betstake must be = jackpotbet.actual_stake' 
						WHEN (contri.StatusID = 103 AND contri.BetStake <> 0) THEN 'Issue: contribution.betstake must be = 0' 
						END AS VARCHAR(1000)) AS 'Comment'
					, contri.BetStake 'contri-betstake'
					, jpbet.actual_stake 'jpbet-actual_stake'
			INTO	#Result7
			FROM	#tempdata contri
				INNER JOIN #tempdata jpbet
					ON contri.transid = jpbet.refno2
			WHERE	contri.gameid IN (2198, 2398, 2998)
					AND jpbet.gameid IN (2179, 2320, 2920)
					AND ((contri.StatusID <> 103 AND contri.BetStake <> jpbet.actual_stake)
						OR (contri.StatusID = 103 AND contri.BetStake <> 0))

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM	#Result7

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Contribution/Jacpot bet ticket: contribution.betstake must be = jackpotbet.actual_stake'

				DROP TABLE #Result7

				RETURN
			END
		END

		-- jackpot bet, jackpot win ticket
		BEGIN
			SELECT TOP 1000 'Jackpot win - Jackpot bet ticket' AS [CASE]
					,jpbet.*					
					,JPwin.transid 'jpwin-transid'
					, CAST(CASE 
						WHEN (jpbet.JackpotInfo LIKE '%jp=1%' AND jpbet.JackpotInfo NOT LIKE '%' + CAST(jpwin.transid AS VARCHAR) + '%') THEN 'Issue: jackpotbet.jackpotinfo must be indicate transid of jackpot win' 
						END AS VARCHAR(1000)) AS 'Comment'
			INTO	#Result8
			FROM	#tempdata jpbet
				LEFT JOIN #tempdata JPwin
					ON jpbet.transid = JPwin.refno2
			WHERE	jpbet.gameid IN (2179, 2320, 2920)
					AND JPwin.gameid IN (2199, 2399, 2999)
					AND (jpbet.JackpotInfo LIKE '%jp=1%' AND jpbet.JackpotInfo NOT LIKE '%' + CAST(jpwin.transid AS VARCHAR) + '%')

			IF @@ROWCOUNT > 0
			BEGIN
				SELECT *
				FROM	#Result8

				SET @ErrMessage = @ErrMessage
					+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
					+ ' - BettransRnG - Jackpot win/Jacpot bet ticket: jackpotbet.jackpotinfo must be indicate transid of jackpot win'
				
				DROP TABLE #Result8

				RETURN
			END

		END
	END
END
GO