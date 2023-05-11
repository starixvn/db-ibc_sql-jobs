/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_GeneralRules_TicketDetailChecking] 
	 @TableName		VARCHAR(50) = NULL 
	,@Today         SMALLDATETIME
	,@yesterday     SMALLDATETIME
	,@transId       VARCHAR(MAX) = NULL 
	,@ErrorTransIds VARCHAR(MAX) = NULL OUTPUT
AS	
/*
	Created: 20230420@July
	Task: Check data between bettrans & bettransLC/bettransRNG
	DB: DBCONSISTENCY-bodb_Consistency
	Revision:
		- 20230420@July: Check data between bettrans & bettransLC/bettransRNG [Redmine: #186426]
	
	Param's Expanation:
*/
BEGIN
	SET @ErrorTransIds = ''

	CREATE TABLE #tempdata(custid INT, username VARCHAR(50), transid BIGINT, ProductID INT, gameid SMALLINT
		, stake MONEY, actual_stake MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
		, winlostdate SMALLDATETIME, status VARCHAR(10), issum BIT, StatusID TINYINT, RefNo BIGINT
	)
	
	DECLARE @sourcedata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype SMALLINT, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8), RefNo BIGINT
	)
	
	DECLARE @targetdata TABLE (custid INT, username VARCHAR(50), matchid INT
		, bettype SMALLINT, winlostdate SMALLDATETIME, status VARCHAR(10)
		, turnover MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY, netstake MONEY
		, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, spositiontaking SMALLMONEY, tpositiontaking SMALLMONEY
		, playerdiscount DECIMAL (9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8), transid BIGINT
	)
 
	DECLARE @tmpProductId TABLE (ProductId INT)
	CREATE TABLE #tmp_transid (transid BIGINT)

	INSERT INTO #tmp_transid (transid)
	SELECT DISTINCT value AS transid
	FROM STRING_SPLIT(@transId, ',')
	WHERE value <> ''

    IF @TableName = 'bettransLC'
	BEGIN
		INSERT INTO #tempdata (custid, username, transid, ProductID, gameid
			, stake, actual_stake
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount
			, winlost, awinlost, mwinlost, swinlost, netstake
			, playercomm, comm, acomm, scomm
			, winlostdate, status, issum, StatusID, RefNo
		)
		SELECT custid, username, transid, ProductID, gameid
			, stake, actual_stake
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount
			, winlost, awinlost, mwinlost, swinlost, NetStake
			, playercomm, comm, acomm, scomm
			, winlostdate, status, issum, StatusID, RefNo
		FROM bodb02.dbo.bettransLC WITH (NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND custid <> 0 --exlude orphan ticket
			AND 1 = CASE WHEN @transId IS NULL THEN 1
						 WHEN @transId IS NOT NULL AND RefNo IN (SELECT transid FROM #tmp_transid) THEN 1
						 ELSE 0 END

		INSERT INTO @sourcedata(custid, username, matchid, bettype, winlostdate, status
			, turnover, winlost, awinlost, swinlost, mwinlost, netstake, scomm, acomm, comm, playercomm
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount, RefNo
		)
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

		INSERT INTO @tmpProductId (ProductId) 
		SELECT DISTINCT matchid AS ProductId
		FROM @sourcedata

		INSERT INTO @targetdata(custid, username, matchid, bettype, winlostdate, status
			, turnover, winlost, awinlost, swinlost, mwinlost, netstake
			, scomm, acomm, comm, playercomm
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount, transid
		)
		SELECT custid, username, matchid, bettype, winlostdate, status
			, SUM(stake) AS stake, SUM(winlost-actual_stake) AS winlost
			, SUM(awinlost) AS awinlost, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost, SUM(ISNULL(oddsspread, 0)) AS netstake
			, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
			, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
			, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
			, transid
		FROM bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND statusid NOT IN (0, 1, 131)
			AND matchid IN ( SELECT ProductId FROM @tmpProductId)
			AND 1 = CASE WHEN @transId IS NULL THEN 1
						 WHEN @transId IS NOT NULL AND transid IN (SELECT transid FROM #tmp_transid) THEN 1
						 ELSE 0 END
		GROUP BY custid, username, matchid, bettype, winlostdate, status, transid
	
		TRUNCATE TABLE #tmp_transid
		
		INSERT INTO #tmp_transid(transid)
		SELECT s.RefNo AS transid
		FROM @sourcedata s
			FULL OUTER JOIN @targetdata t ON s.RefNo = t.transid
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

			SELECT TOP (100) @ErrorTransIds = @ErrorTransIds + ',' + CAST(transid AS VARCHAR)
			FROM #tmp_transid
	END

	IF @TableName = 'bettransRNG'
	BEGIN
		INSERT INTO #tempdata (custid, username, transid, ProductID, gameid
		, stake, actual_stake
		, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		, playerdiscount, discount, adiscount, sdiscount
		, winlost, awinlost, mwinlost, swinlost
		, playercomm, comm, acomm, scomm
		, winlostdate, status, issum, StatusID, RefNo
		)
		SELECT custid, username, transid, ProductID, gameid
			, stake, actual_stake
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount
			, winlost, awinlost, mwinlost, swinlost
			, playercomm, comm, acomm, scomm
			, winlostdate, status, issum, StatusID, RefNo
		FROM bodb02.dbo.bettransRNG WITH (NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND custid <> 0 --exlude orphan ticket
			AND 1 = CASE WHEN @transId IS NULL THEN 1
						 WHEN @transId IS NOT NULL AND RefNo IN (SELECT transid FROM #tmp_transid) THEN 1
						 ELSE 0 END

		INSERT INTO @sourcedata(custid, username, matchid, bettype, winlostdate, status
			, turnover, winlost, awinlost, swinlost, mwinlost, scomm, acomm, comm, playercomm
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount, RefNo
		)
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
			, RefNo
		FROM #tempdata
		WHERE issum = 1
		GROUP BY custid, username, productid, gameid, winlostdate, RefNo

		INSERT INTO @tmpProductId (ProductId) 
		SELECT DISTINCT matchid AS ProductId
		FROM @sourcedata

		INSERT INTO @targetdata(custid, username, matchid, bettype, winlostdate, status
			, turnover, winlost, awinlost, swinlost, mwinlost
			, scomm, acomm, comm, playercomm
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
			, playerdiscount, discount, adiscount, sdiscount, transid
		)
		SELECT custid, username, matchid, bettype, winlostdate, status
			, SUM(stake) AS stake, SUM(winlost-actual_stake) AS winlost
			, SUM(awinlost) AS awinlost, SUM(swinlost) AS swinlost, SUM(mwinlost) AS mwinlost
			, SUM(scomm) AS scomm, SUM(acomm) AS acomm, SUM(comm) AS comm, SUM(playercomm) AS playercomm
			, AVG(apositiontaking) AS apositiontaking, AVG(mpositiontaking) AS mpositiontaking, AVG(spositiontaking) AS spositiontaking, AVG(tpositiontaking) AS tpositiontaking
			, AVG(playerdiscount) AS playerdiscount, AVG(discount) AS discount, AVG(adiscount) AS adiscount, AVG(sdiscount) AS sdiscount
			, transid
		FROM bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE (winlostdate = @Today OR winlostdate = @yesterday)
			AND statusid NOT IN (0, 1, 131)
			AND matchid IN ( SELECT ProductId FROM @tmpProductId)
			AND 1 = CASE WHEN @transId IS NULL THEN 1
						 WHEN @transId IS NOT NULL AND transid IN (SELECT transid FROM #tmp_transid) THEN 1
						 ELSE 0 END
		GROUP BY custid, username, matchid, bettype, winlostdate, status, transid
	
		TRUNCATE TABLE #tmp_transid
		
		INSERT INTO #tmp_transid(transid)
		SELECT s.RefNo AS transid
		FROM @sourcedata s
			FULL OUTER JOIN @targetdata t ON s.RefNo = t.transid
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

		SELECT TOP (100) @ErrorTransIds = @ErrorTransIds + ',' + CAST(transid AS VARCHAR)
		FROM #tmp_transid

	END
	
	DROP TABLE #tempdata
	DROP TABLE #tmp_transid
END