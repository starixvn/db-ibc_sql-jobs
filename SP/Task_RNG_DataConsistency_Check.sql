USE [bodb02]
GO
ALTER PROCEDURE dbo.Task_RNG_DataConsistency_Check @FromDate SMALLDATETIME
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
*/
BEGIN
	SET @ErrMessage = ''

	CREATE TABLE #tempdata(custid INT, username VARCHAR(50), transid BIGINT, ProductID INT, gameid smallint
		, stake MONEY, actual_stake MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
		, playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
		, winlostdate SMALLDATETIME, status VARCHAR(10), issum bit, StatusID tinyint)
	
	DECLARE @sourcedata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8))

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
		, winlostdate, status, issum, StatusID)
	SELECT custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID
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
	
	SELECT TOP 1 'Case 1' AS [CASE], s.*, t.*
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
	
	SELECT TOP 1 'Case 2,3,4,5' AS [CASE]
		, t.*
		, CASE WHEN (winlost > actual_stake AND status <> 'WON') THEN 'Issue: Status should be WON'
				 WHEN (winlost = actual_stake AND status NOT IN ('DRAW', 'REFUND', 'VOID')) THEN 'Issue: Status should be DRAW/REFUND'
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
			OR (winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID'))--Case 3: Check data in BettransRnG - if winlost - actual_stake = 0 -> status=DRAW
			OR (winlost < actual_stake AND status <> 'LOSE')--Case 4: Check data in BettransRnG - if winlost - actual_stake < 0 -> status=LOSE
			
			OR (-(winlost - actual_stake) * apositiontaking <> awinlost) --Case 5: Check data in BettransRnG - awinlost, playercomm are calculated correctly
			OR (-(winlost - actual_stake) * mpositiontaking <> mwinlost)
			OR (-(winlost - actual_stake) * spositiontaking <> swinlost)
			
			OR (statusid IN (112,113) AND (cast(stake * playerdiscount AS money) <> playercomm)) --Case 5b: playercomm is wrong
			OR (statusid IN (112,113) AND (cast(stake * discount * (1 - apositiontaking) AS money) <> comm)) --Case 5c: comm is wrong
			OR (statusid IN (112,113) AND (cast(stake * adiscount * (1 - (mpositiontaking + apositiontaking)) AS money) <> acomm)) --Case 5d: acomm is wrong		
			OR (statusid IN (112,113) AND (cast(stake * sdiscount * (1 - (spositiontaking + mpositiontaking + apositiontaking)) AS money) <> scomm)) --Case 5e: scomm is wrong
			)
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 2,3,4,5: Check status/awinlost/mwinlost/swinlost/playercomm/comm/acomm/scomm of tickets in bettransRNG.'
		RETURN
	END
	
	SELECT * 
	INTO #tempdataSetting
	FROM (
	SELECT t.*,row_number() OVER(PARTITION BY custid ORDER BY transid DESC) AS rn
	FROM #tempdata t
	) tmp
	WHERE rn = 1
	
	
	SELECT * 
	INTO #Sport_Bettype_Reference_Setting
	FROM DBTXN.bodb02.dbo.Sport_Bettype_Reference_Setting WITH(NOLOCK) 
	WHERE sporttype = @ProductId AND isLive = 0 AND Site = 'ALL'
	
	/*DCS checking*/
	/*
	--PT@Credit
	SELECT TOP 1 'Case 6.1' AS [CASE]
		, main.transid, main.custid, main.productid, main.gameid
		,main.apositiontaking, ISNULL(idvpt.AgentPT, grppt.AgentPT) AgentPT
		,main.mpositiontaking, ISNULL(idvpt.MasterPT, grppt.MasterPT) MasterPT
		,main.spositiontaking, ISNULL(idvpt.SuperPT, grppt.SuperPT) SuperPT
	FROM #tempdataSetting main WITH(NOLOCK)
		INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON ci.custid = main.custid
		INNER JOIN #Sport_Bettype_Reference_Setting ref WITH(NOLOCK) 
				ON ref.Sporttype = main.productid 
					AND ref.Bettype = main.gameid
					AND ref.isLicensee = 0
		LEFT JOIN dbo.CustPTSetting3rd_Member idvpt WITH(NOLOCK) 
				ON idvpt.custid = main.custid
					AND idvpt.sporttype = ref.SportTypeRefPT
					AND idvpt.bettype = ref.BetTypeRefPT
					AND idvpt.isLive = ref.isLivePT
		LEFT JOIN dbo.CustPTGroupSetting3rd_Member grppt WITH(NOLOCK) 
				ON grppt.AgentID = ci.recommend
					AND grppt.sporttype = ref.SportTypeRefPT
					AND grppt.bettype = ref.BetTypeRefPT
					AND grppt.isLive = ref.isLivePT
	WHERE ci.srecommend NOT IN (SELECT CustID FROM dbo.Dep_CustSuper WITH(NOLOCK))
		AND 
		(
			main.apositiontaking * 100 <> ISNULL(idvpt.AgentPT, grppt.AgentPT)
			OR
			main.mpositiontaking * 100 <> ISNULL(idvpt.MasterPT, grppt.MasterPT)
			OR
			main.spositiontaking * 100 <> ISNULL(idvpt.SuperPT, grppt.SuperPT)
		)
		
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 6.1: Check inconsistent PT in bettransRNG.'
		RETURN
	END
	
	--PT@Deposit
	SELECT TOP 1 'Case 6.2' AS [CASE]
		, main.transid, main.custid, main.productid, main.gameid
		,main.apositiontaking, ISNULL(idvpt.AgentPT, grppt.AgentPT) AgentPT
		,main.mpositiontaking, ISNULL(idvpt.MasterPT, grppt.MasterPT) MasterPT
		,main.spositiontaking, ISNULL(idvpt.SuperPT, grppt.SuperPT) SuperPT
	FROM #tempdataSetting main WITH(NOLOCK)
		INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON ci.custid = main.custid
		INNER JOIN #Sport_Bettype_Reference_Setting ref WITH(NOLOCK) 
				ON ref.Sporttype = main.productid 
					AND ref.Bettype = main.gameid
					AND ref.isLicensee = 1
		LEFT JOIN Dep_CustPTSetting_Member idvpt WITH(NOLOCK) 
				ON idvpt.custid = main.custid
					AND idvpt.sporttype = ref.SportTypeRefPT
					AND idvpt.bettype = ref.BetTypeRefPT
					AND idvpt.isLive = ref.isLivePT
		LEFT JOIN dbo.Dep_CustPTGroupSetting_Member grppt WITH(NOLOCK) 
				ON grppt.AgentID = ci.recommend
					AND grppt.sporttype = ref.SportTypeRefPT
					AND grppt.bettype = ref.BetTypeRefPT
					AND grppt.isLive = ref.isLivePT
	WHERE ci.srecommend IN (SELECT CustID FROM dbo.Dep_CustSuper WITH(NOLOCK))
		AND 
		(
			main.apositiontaking * 100 <> ISNULL(idvpt.AgentPT, grppt.AgentPT)
			OR
			main.mpositiontaking * 100 <> ISNULL(idvpt.MasterPT, grppt.MasterPT)
			OR
			main.spositiontaking * 100 <> ISNULL(idvpt.SuperPT, grppt.SuperPT)
		)
		
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 6.2: Check inconsistent PT in bettransRNG.'
		RETURN
	END
	*/
	--Comm@Credit
	SELECT TOP 1 'Case 7.1' AS [CASE]
		, main.transid, main.custid, main.productid, main.gameid
		, main.playerdiscount, comm.PlayerDiscount PlayerDiscount
		, main.discount, comm.AgentDiscount AgentDiscount
		, main.adiscount, comm.MasterDiscount MasterDiscount
		, main.sdiscount, comm.SuperDiscount SuperDiscount
	FROM #tempdataSetting main WITH(NOLOCK)
		INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON ci.custid = main.custid
		INNER JOIN #Sport_Bettype_Reference_Setting ref WITH(NOLOCK) 
				ON ref.Sporttype = main.productid 
					AND ref.Bettype = main.gameid
					AND ref.isLicensee = 0
		INNER JOIN dbo.CustDiscount3rd_member comm WITH(NOLOCK) 
				ON comm.custid = main.custid
					AND comm.sporttype = ref.SportTypeRefComm
					AND comm.bettype = ref.BetTypeRefComm
	WHERE ci.srecommend NOT IN (SELECT CustID FROM dbo.Dep_CustSuper WITH(NOLOCK))
		AND 
		(
			main.playerdiscount <> comm.PlayerDiscount
			OR
			main.discount <> comm.AgentDiscount
			OR
			main.adiscount <> comm.MasterDiscount
			OR
			main.sdiscount <> comm.SuperDiscount
		)

	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage
			+ 'Inconsistent - RnG Game - ProductId: ' + CAST(@ProductId AS VARCHAR)
			+ ' - Case 7.1: Check inconsistent Comm in bettransRNG.'
		RETURN
	END
END
GRANT VIEW DEFINITION ON Task_RNG_DataConsistency_Check TO vnteam

GO
GRANT EXECUTE ON [dbo].[Task_RNG_DataConsistency_Check] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_RNG_DataConsistency_Check] TO [vnteam] AS [dbo]