/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_LC_DataConsistency_Check] @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @ProductId INT

	, @ErrMessage VARCHAR(512) = '' OUTPUT
AS
/*
	Created: 20161003@Patrick
	Task: Check data between bettrans & bettransLC for LC Game
	DB: DBTP/bodb02
	Revision:
*/
BEGIN
	SET @ErrMessage = ''

	CREATE TABLE #tempdata(custid INT, username VARCHAR(50), transid BIGINT, ProductID INT, gameid smallint
		, stake MONEY, actual_stake MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
		, winlostdate SMALLDATETIME, status VARCHAR(10), issum bit, StatusID tinyint, RefNo bigint)
	
	DECLARE @sourcedata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8), RefNo bigint)

	DECLARE @targetdata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8), transId bigint)

	INSERT INTO #tempdata (custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost, netstake
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID, RefNo)
	SELECT custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost, NetStake
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID, RefNo
	FROM dbo.bettransLC WITH (NOLOCK)
	WHERE productID = @ProductId
		AND winlostdate BETWEEN @FromDate AND @ToDate

	INSERT INTO @sourcedata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, netstake, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount, RefNo)
	SELECT custid, username, productid, gameID, winlostdate
		, CASE WHEN SUM(winlost-actual_stake) > 0 THEN 'WON'
			WHEN SUM(winlost-actual_stake) < 0 THEN 'LOSE'
		 ELSE 'DRAW' END AS STATUS
		, SUM(stake) AS stake, SUM(winlost - actual_stake) AS winlost, SUM(awinlost) AS awinlost
		, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost, SUM(netstake) AS netstake
		, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
		, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking
		, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
		, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
		, RefNo
	FROM #tempdata
	WHERE issum = 1
	GROUP BY custid, username, productid, gameid, winlostdate, RefNo

	INSERT INTO @targetdata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, netstake
		, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount, transId)
	SELECT custid, username, matchid, bettype, winlostdate, status
		, SUM(stake) AS stake, SUM(winlost-actual_stake) AS winlost
		, SUM(awinlost) AS awinlost, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost, SUM(ISNULL(oddsspread, 0)) AS netstake
		, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
		, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
		, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
		, transid
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = @ProductId
		AND winlostdate BETWEEN @fromdate AND @todate
		AND statusid NOT IN (0, 1, 131)
	GROUP BY custid, username, matchid, bettype, winlostdate, status, transid
	
	SELECT TOP 10 'Case 1' AS [CASE], s.*, t.*
	FROM @sourcedata s
		FULL OUTER JOIN @targetdata t ON s.RefNo = t.transId
	WHERE ISNULL(s.turnover, 0) <> ISNULL(t.turnover, 0)
		OR ISNULL(s.winlost, 0) <> ISNULL(t.winlost, 0)
		OR ISNULL(s.swinlost, 0) <> ISNULL(t.swinlost, 0) 
		OR ISNULL(s.mwinlost, 0) <> ISNULL(t.mwinlost, 0) 
		OR ISNULL(s.awinlost, 0) <> ISNULL(t.awinlost, 0)
		OR ISNULL(s.netstake, 0) <> ISNULL(t.netstake, 0)
	
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
			+ 'Inconsistent - LC Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 1: Check ticket details between bettrans AND bettransLC.'
		RETURN
	END
	
	SELECT TOP 10 'Case 2,3,4,5' AS [CASE]
		, t.*
		, CASE WHEN (winlost > actual_stake AND status <> 'WON') THEN 'Issue: Status should be WON'
				 WHEN (winlost = actual_stake AND status NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT')) THEN 'Issue: Status should be DRAW/REFUND/VOID/REJECT'
				 WHEN (winlost < actual_stake AND status <> 'LOSE') THEN 'Issue: Status should be LOSE'
				 WHEN (-(winlost - actual_stake) * apositiontaking <> awinlost) THEN 'Issue: awinlost is calculated wrongly' 
				 WHEN (-(winlost - actual_stake) * mpositiontaking <> mwinlost) THEN 'Issue: mwinlost is calculated wrongly' 
				 WHEN (-(winlost - actual_stake) * spositiontaking <> swinlost) THEN 'Issue: swinlost is calculated wrongly' 
				 WHEN (netstake * playerdiscount <> playercomm) THEN 'Issue: playercomm is wrong'
				 WHEN (netstake * discount * (1 - apositiontaking) <> comm) THEN 'Issue: comm is wrong'
				 WHEN (netstake * adiscount * (1 - (mpositiontaking + apositiontaking)) <> acomm) THEN 'Issue: acomm is wrong'
				 WHEN (netstake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) <> scomm) THEN 'Issue: scomm is wrong'
			END AS 'Comment'
	FROM #tempdata t
	WHERE StatusId NOT IN (0,1)
		AND ((winlost > actual_stake AND status <> 'WON')--Case 2: Check data in BettransLC - if winlost - actual_stake > 0 -> status=WON
			OR (winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))--Case 3: Check data in BettransLC - if winlost - actual_stake = 0 -> status=DRAW
			OR (winlost < actual_stake AND status <> 'LOSE')--Case 4: Check data in BettransLC - if winlost - actual_stake < 0 -> status=LOSE
			
			OR (-(winlost - actual_stake) * apositiontaking <> awinlost) --Case 5: Check data in BettransLC - awinlost, playercomm are calculated correctly
			OR (-(winlost - actual_stake) * mpositiontaking <> mwinlost)
			OR (-(winlost - actual_stake) * spositiontaking <> swinlost)
			
			OR (statusid IN (112,113) AND (cast(netstake * playerdiscount AS money) <> playercomm)) --Case 5b: playercomm is wrong
			OR (statusid IN (112,113) AND (cast(netstake * discount * (1 - apositiontaking) AS money) <> comm)) --Case 5c: comm is wrong
			OR (statusid IN (112,113) AND (cast(netstake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) --Case 5d: acomm is wrong		
			OR (statusid IN (112,113) AND (cast(netstake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)) --Case 5e: scomm is wrong
			)
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - LC Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 2,3,4,5: Check status/awinlost/mwinlost/swinlost/playercomm/comm/acomm/scomm of tickets in bettransLC.'
		RETURN
	END
END
