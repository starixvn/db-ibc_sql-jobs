/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="vnteam" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_GeneralRules_bettransLCChecking] 
	 @CheckMode		INT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20230420@July
	Task: Check data between bettrans & bettransLC
	DB: DBCONSISTENCY-bodb_Consistency
	Revision:
		- 20230420@July: Check data between bettrans & bettransLC [Redmine: #186426]
	
	Param's Expanation:
	@CheckMode:
		+ 1: Check ticket details between bettrans and bettransLC
		+ 2: Check wrong status of tickets in bettransLC
*/
BEGIN
	DECLARE @transId		VARCHAR(MAX)
			,@Today			SMALLDATETIME
			,@yesterday		SMALLDATETIME 
			,@ProductIds	VARCHAR(MAX) =''

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	CREATE TABLE #tempdata(custid INT, username VARCHAR(50), transid BIGINT, ProductID INT, gameid smallint
		, stake MONEY, actual_stake MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
		, winlostdate SMALLDATETIME, status VARCHAR(10), issum bit, StatusID tinyint)
	
	DECLARE @sourcedata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8))
	
	DECLARE @tmpProductId TABLE (ProductId INT)

	DECLARE @targetdata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype smallint, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8))

	INSERT INTO #tempdata (custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost, netstake
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID)
	SELECT custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost, NetStake
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID
	FROM dbo.bettransLC WITH (NOLOCK)
	WHERE (winlostdate = @Today OR winlostdate = @yesterday)

	INSERT INTO @sourcedata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, netstake, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount)
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
	FROM #tempdata
	WHERE issum = 1
	GROUP BY custid, username, productid, gameid, winlostdate

	INSERT INTO @tmpProductId (ProductId) 
	SELECT DISTINCT matchid AS ProductId
	FROM @sourcedata

	INSERT INTO @targetdata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, netstake
		, scomm, acomm, comm, playercomm
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount)
	SELECT custid, username, matchid, bettype, winlostdate, status
		, SUM(stake) AS stake, SUM(winlost-actual_stake) AS winlost
		, SUM(awinlost) AS awinlost, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost, SUM(ISNULL(oddsspread, 0)) AS netstake
		, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
		, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
		, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE (winlostdate = @Today OR winlostdate = @yesterday)
		AND statusid NOT IN (0, 1, 131)
		AND matchid IN ( SELECT ProductId FROM @tmpProductId)
	GROUP BY custid, username, matchid, bettype, winlostdate, status
	
	IF @CheckMode = 1
	BEGIN
		DELETE FROM @tmpProductId
		
		INSERT INTO @tmpProductId(ProductId)
		SELECT DISTINCT s.matchid
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

		SELECT TOP (100) @ProductIds = @ProductIds + ',' + CAST(ProductId AS VARCHAR(50))
		FROM	@tmpProductId

		IF @ProductIds <> ''
		BEGIN
			SELECT	 @ProductIds = SUBSTRING(@ProductIds, 2, LEN(@ProductIds) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Check ticket details between bettrans and bettransLC '
					,@SampleData = 'bettransLC.ProductId in (' + @ProductIds + ')'
		END
		RETURN;
		
	END
	IF @CheckMode = 2
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM #tempdata
		WHERE StatusId NOT IN (0,1)
			AND (
					(winlost > actual_stake AND status <> 'WON')										--Case 2: if winlost - actual_stake > 0 -> status=WON
				OR	(winlost = actual_stake AND status  NOT IN ('DRAW', 'REFUND', 'VOID', 'REJECT'))	--Case 3: if winlost - actual_stake = 0 -> status=DRAW
				OR	(winlost < actual_stake AND status <> 'LOSE')										--Case 4: if winlost - actual_stake < 0 -> status=LOSE
				)
			AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
	
		IF @transId <> ''
		BEGIN
			SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Check wrong status of tickets in bettransLC'
					,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
		RETURN;
		
	END
END
GO