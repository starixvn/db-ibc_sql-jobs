/*<info serverAlias="DBTXN-bodb02"></info>*/
ALTER PROCEDURE [dbo].[Task_sum_winloss_14]
	@WinlostDate	SMALLDATETIME
	,@CustIds		VARCHAR(MAX) = ''
AS

/*
	Created: 20190708@Percy
	DB: DBTXN.bodb02
	Task: Regen data for sum_winloss on bettrans14

	Revisions:
		- 20190708@Percy: Initialize SP [RedmineID: #115377]
*/

BEGIN
	SET NOCOUNT ON

	-- Get Bet Types
	DECLARE @ProductIds VARCHAR(MAX)
	SELECT  @ProductIds = COALESCE(@ProductIds + ',', '') + CONVERT(VARCHAR(10), ProductId) FROM dbo.Products WITH (NOLOCK)

	CREATE TABLE #Bettypes (ProductId INT, SportTypeRef SMALLINT, BettypeRef SMALLINT, Bettype SMALLINT)
	INSERT INTO #Bettypes (ProductId, SportTypeRef, BettypeRef, Bettype)
	SELECT f.ProductID, f.SportType AS SportTypeRef, f.BetType AS BettypeRef, s.BetType
	FROM dbo.f_SumWinloss_ConditionSel(@ProductIds) f
		CROSS APPLY (
			SELECT DISTINCT s.BetType FROM dbo.SportBettypeMatrix s WITH (NOLOCK)
			WHERE f.ProductID = s.ProductID
				AND (f.ProductID <> 6 OR f.SportType = s.SportType)
		) AS s
	-- End Get Bet Types

	-- Get Customer Info
	BEGIN
		-- Super
		CREATE TABLE #tmpSuper (srecommend INT)
		INSERT INTO #tmpSuper (srecommend)
		SELECT DISTINCT c.srecommend
		FROM CustDB.dbo.Customer c WITH (NOLOCK)
			CROSS APPLY (
				SELECT val FROM bodb02.dbo.strSplit(@CustIds, ',') f WHERE c.custid = f.val
			) AS tmp

		-- Member
		CREATE TABLE #tmpCust (custid INT, username NVARCHAR(50), recommend INT, mrecommend INT, srecommend INT)
		INSERT INTO #tmpCust (custid, username, recommend, mrecommend, srecommend)
		SELECT c.custid, c.username, c.recommend, c.mrecommend, c.srecommend
		FROM CustDB.dbo.Customer c WITH (NOLOCK)
			INNER JOIN #tmpSuper s ON c.srecommend = s.srecommend
		WHERE c.roleid = 1
	END
	-- End Get Customer Info

	-- Get Data From bettrans14
	BEGIN
		CREATE TABLE #tmpBettrans
		(
			winlostdate			DATETIME
			,username			NVARCHAR(50)
			,custid				INT
			,roleid				INT
			,recommend			INT
			,mrecommend			INT
			,srecommend			INT
			,turnover			MONEY
			,winlost			MONEY
			,awinlost			MONEY
			,mwinlost			MONEY
			,swinlost			MONEY
			,playercomm			MONEY
			,comm				MONEY
			,acomm				MONEY
			,scomm				MONEY
			,BetCount			INT
			,member_grosscomm	MONEY
			,agent_grosscomm	MONEY
			,master_grosscomm	MONEY
			,super_grosscomm	MONEY
			,sporttype			SMALLINT
			,bettype			SMALLINT
			,member_netTurnover	MONEY
			,agent_netTurnover	MONEY
			,master_netTurnover	MONEY
			,super_netTurnover	MONEY
			,TurnoverNoDraw		MONEY
		)
		INSERT INTO #tmpBettrans
		(
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,member_grosscomm
			,agent_grosscomm
			,master_grosscomm
			,super_grosscomm
			,sporttype
			,bettype
			,member_netTurnover
			,agent_netTurnover
			,master_netTurnover
			,super_netTurnover
			,TurnoverNoDraw
		)
		SELECT
			b.winlostdate
			,c.username
			,b.custid
			,1 AS roleid
			,c.recommend
			,c.mrecommend
			,c.srecommend
			,SUM(ABS(b.stake)) AS turnover
			,SUM(b.winlost - b.actual_stake) AS winlost
			,SUM(b.awinlost) AS awinlost
			,SUM(b.mwinlost) AS mwinlost
			,SUM(b.swinlost) AS swinlost
			,SUM(b.playercomm) AS playercomm
			,SUM(b.comm) AS comm
			,SUM(b.acomm) AS acomm
			,SUM(b.scomm) AS scomm
			,SUM(CASE	WHEN b.bettype = 500 THEN 0
						ELSE 1 END) AS BetCount
			,SUM(CASE	WHEN b.apositiontaking = 1 THEN 0
						ELSE ISNULL(b.comm / (1 - b.apositiontaking), 0) END) AS member_grosscomm
			,SUM(CASE	WHEN b.apositiontaking + b.mpositiontaking = 1 THEN 0
						ELSE ISNULL(b.acomm / (1 - b.apositiontaking - b.mpositiontaking), 0) END) AS agent_grosscomm
			,SUM(CASE	WHEN b.tpositiontaking = 1 THEN 0
						ELSE ISNULL(b.scomm / (1 - b.tpositiontaking), 0) END) AS master_grosscomm
			,SUM(CASE	WHEN b.apositiontaking = 1 THEN 0
						ELSE ISNULL(b.scomm / (1 - b.tpositiontaking), 0) END) AS super_grosscomm
			,bt.sporttypeRef AS sporttype
			,bt.bettypeRef AS bettype
			,0 AS member_netTurnover
			,SUM(ABS(b.stake) * b.apositiontaking) AS agent_netTurnover
			,SUM(ABS(b.stake) * b.mpositiontaking) AS master_netTurnover
			,SUM(ABS(b.stake) * b.spositiontaking) AS super_netTurnover
			,SUM(CASE
					WHEN bt.ProductId = 1 AND b.statusID IN (112, 113) AND b.modds IN (-0.25, 0.25) THEN ABS(b.stake) / 2 -- SportsBook
					WHEN bt.ProductId = 1 AND b.statusID = 111 THEN 0 -- SportsBook
					WHEN bt.ProductId = 21 THEN b.oddsspread -- Allbet
					ELSE ABS(b.stake) END) AS TurnoverNoDraw
		FROM #tmpCust c
			CROSS APPLY (
				SELECT
					winlostdate
					,b.custid
					,b.stake
					,b.actual_stake
					,b.winlost
					,b.awinlost
					,b.mwinlost
					,b.swinlost
					,b.playercomm
					,b.comm
					,b.acomm
					,b.scomm
					,b.oddsspread
					,b.apositiontaking
					,b.mpositiontaking
					,b.spositiontaking
					,b.tpositiontaking
					,b.bettype
					,b.modds
					,b.statusID
				FROM dbo.bettrans14 b WITH (NOLOCK)
				WHERE b.winlostdate = @WinlostDate
					AND c.custid = b.custid
					AND b.statusID IN (111,112,113)
			) AS b
			INNER JOIN #Bettypes bt ON b.bettype = bt.bettype
		GROUP BY
			b.winlostdate
			,c.username
			,b.custid
			,c.recommend
			,c.mrecommend
			,c.srecommend
			,bt.sporttypeRef
			,bt.bettypeRef
	END
	-- End Get Data From bettrans14

	DROP TABLE #tmpCust
	DROP TABLE #Bettypes

	-- Sum up Data by Level
	BEGIN
		CREATE TABLE #tmpSum_winloss
		(
			winlostdate			DATETIME
			,username			NVARCHAR(50)
			,custid				INT
			,roleid				INT
			,recommend			INT
			,mrecommend			INT
			,srecommend			INT
			,turnover			MONEY
			,winlost			MONEY
			,awinlost			MONEY
			,mwinlost			MONEY
			,swinlost			MONEY
			,playercomm			MONEY
			,comm				MONEY
			,acomm				MONEY
			,scomm				MONEY
			,BetCount			INT
			,grosscomm			MONEY
			,sporttype			SMALLINT
			,bettype			SMALLINT
			,netTurnover		MONEY
			,TurnoverNoDraw		MONEY
		)

		-- Member
		INSERT INTO #tmpSum_winloss
		(
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		)
		SELECT
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,member_grosscomm
			,sporttype
			,bettype
			,member_netTurnover
			,TurnoverNoDraw
		FROM #tmpBettrans

		-- Agent
		;WITH CTE_Agent AS
		(
			SELECT
				winlostdate
				,recommend
				,mrecommend
				,srecommend
				,SUM(turnover) AS turnover
				,SUM(winlost) AS winlost
				,SUM(awinlost) AS awinlost
				,SUM(mwinlost) AS mwinlost
				,SUM(swinlost) AS swinlost
				,SUM(playercomm) AS playercomm
				,SUM(comm) AS comm
				,SUM(acomm) AS acomm
				,SUM(scomm) AS scomm
				,SUM(BetCount) AS BetCount
				,SUM(agent_grosscomm) AS grosscomm
				,sporttype
				,bettype
				,SUM(agent_netTurnover) AS netTurnover
				,SUM(TurnoverNoDraw) AS TurnoverNoDraw
			FROM #tmpBettrans
			GROUP BY
				winlostdate
				,recommend
				,mrecommend
				,srecommend
				,sporttype
				,bettype
		)
		INSERT INTO #tmpSum_winloss
		(
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		)
		SELECT
			winlostdate
			,username
			,recommend AS custid
			,2 AS roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		FROM CTE_Agent a
			CROSS APPLY (
				SELECT username FROM CustDB.dbo.Customer c WITH (NOLOCK) WHERE a.recommend = c.custid
			) AS c

		-- Master
		;WITH CTE_Master AS
		(
			SELECT
				winlostdate
				,mrecommend
				,srecommend
				,SUM(turnover) AS turnover
				,SUM(winlost) AS winlost
				,SUM(awinlost) AS awinlost
				,SUM(mwinlost) AS mwinlost
				,SUM(swinlost) AS swinlost
				,SUM(playercomm) AS playercomm
				,SUM(comm) AS comm
				,SUM(acomm) AS acomm
				,SUM(scomm) AS scomm
				,SUM(BetCount) AS BetCount
				,SUM(master_grosscomm) AS grosscomm
				,sporttype
				,bettype
				,SUM(master_netTurnover) AS netTurnover
				,SUM(TurnoverNoDraw) AS TurnoverNoDraw
			FROM #tmpBettrans
			GROUP BY
				winlostdate
				,mrecommend
				,srecommend
				,sporttype
				,bettype
		)
		INSERT INTO #tmpSum_winloss
		(
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		)
		SELECT
			winlostdate
			,username
			,mrecommend AS custid
			,3 AS roleid
			,0 AS recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		FROM CTE_Master m
			CROSS APPLY (
				SELECT username FROM CustDB.dbo.Customer c WITH (NOLOCK) WHERE m.mrecommend = c.custid
			) AS c

		-- Super
		;WITH CTE_Super AS
		(
			SELECT
				winlostdate
				,srecommend
				,SUM(turnover) AS turnover
				,SUM(winlost) AS winlost
				,SUM(awinlost) AS awinlost
				,SUM(mwinlost) AS mwinlost
				,SUM(swinlost) AS swinlost
				,SUM(playercomm) AS playercomm
				,SUM(comm) AS comm
				,SUM(acomm) AS acomm
				,SUM(scomm) AS scomm
				,SUM(BetCount) AS BetCount
				,SUM(super_grosscomm) AS grosscomm
				,sporttype
				,bettype
				,SUM(super_netTurnover) AS netTurnover
				,SUM(TurnoverNoDraw) AS TurnoverNoDraw
			FROM #tmpBettrans
			GROUP BY
				winlostdate
				,srecommend
				,sporttype
				,bettype
		)
		INSERT INTO #tmpSum_winloss
		(
			winlostdate
			,username
			,custid
			,roleid
			,recommend
			,mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		)
		SELECT
			winlostdate
			,username
			,srecommend AS custid
			,4 AS roleid
			,0 AS recommend
			,0 AS mrecommend
			,srecommend
			,turnover
			,winlost
			,awinlost
			,mwinlost
			,swinlost
			,playercomm
			,comm
			,acomm
			,scomm
			,BetCount
			,grosscomm
			,sporttype
			,bettype
			,netTurnover
			,TurnoverNoDraw
		FROM CTE_Super s
			CROSS APPLY (
				SELECT username FROM CustDB.dbo.Customer c WITH (NOLOCK) WHERE s.srecommend = c.custid
			) AS c

		DROP TABLE #tmpBettrans
	END
	-- End Sum up Data by Level

	-- Compare data with target
	DECLARE @RowCount INT

	BEGIN
		;WITH CTE_s AS
		(
			SELECT
				winlostdate
				,username
				,custid
				,roleid
				,recommend
				,mrecommend
				,srecommend
				,turnover
				,winlost
				,awinlost
				,mwinlost
				,swinlost
				,playercomm
				,comm
				,acomm
				,scomm
				,BetCount
				,grosscomm
				,sporttype
				,bettype
				,netTurnover
				,TunroverNoDraw -- TurnoverNoDraw
			FROM dbo.sum_winloss s WITH (NOLOCK)
			WHERE s.winlostdate = @WinlostDate
				AND EXISTS (SELECT 1 FROM #tmpSuper ts WHERE s.srecommend = ts.srecommend)
		)
		SELECT @RowCount = COUNT(1)
		FROM #tmpSum_winloss tmp
			FULL OUTER JOIN CTE_s s
				ON		tmp.winlostdate	= s.winlostdate
					AND tmp.custid		= s.custid
					AND tmp.sporttype	= s.sporttype
					AND tmp.bettype		= s.bettype
		WHERE tmp.custid IS NULL
			OR s.custid IS NULL
			OR tmp.username				<> s.username
			OR tmp.roleid				<> s.roleid
			OR tmp.recommend			<> s.recommend
			OR tmp.mrecommend			<> s.mrecommend
			OR tmp.srecommend			<> s.srecommend
			OR tmp.turnover				<> s.turnover
			OR tmp.winlost				<> s.winlost
			OR tmp.awinlost				<> s.awinlost
			OR tmp.mwinlost				<> s.mwinlost
			OR tmp.swinlost				<> s.swinlost
			OR tmp.playercomm			<> s.playercomm
			OR tmp.comm					<> s.comm
			OR tmp.acomm				<> s.acomm
			OR tmp.scomm				<> s.scomm
			OR tmp.BetCount				<> s.BetCount
			OR tmp.grosscomm			<> s.grosscomm
			OR tmp.netTurnover			<> s.netTurnover
			OR tmp.TurnoverNoDraw		<> s.TunroverNoDraw -- TurnoverNoDraw
	END
	-- End Compare data with target

	-- Regen data
	IF @RowCount <> 0
	BEGIN
		MERGE dbo.sum_winloss AS TARGET
		USING #tmpSum_winloss AS SOURCE
			ON		TARGET.winlostdate	= SOURCE.winlostdate
				AND	TARGET.custid		= SOURCE.custid
				AND TARGET.sporttype	= SOURCE.sporttype
				AND TARGET.bettype		= SOURCE.bettype
		WHEN MATCHED THEN UPDATE
			SET	TARGET.username			= SOURCE.username
				,TARGET.roleid			= SOURCE.roleid
				,TARGET.recommend		= SOURCE.recommend
				,TARGET.mrecommend		= SOURCE.mrecommend
				,TARGET.srecommend		= SOURCE.srecommend
				,TARGET.turnover		= SOURCE.turnover
				,TARGET.winlost			= SOURCE.winlost
				,TARGET.awinlost		= SOURCE.awinlost
				,TARGET.mwinlost		= SOURCE.mwinlost
				,TARGET.swinlost		= SOURCE.swinlost
				,TARGET.playercomm		= SOURCE.playercomm
				,TARGET.comm			= SOURCE.comm
				,TARGET.acomm			= SOURCE.acomm
				,TARGET.scomm			= SOURCE.scomm
				,TARGET.BetCount		= SOURCE.BetCount
				,TARGET.grosscomm		= SOURCE.grosscomm
				,TARGET.netTurnover		= SOURCE.netTurnover
				,TARGET.TunroverNoDraw	= SOURCE.TurnoverNoDraw -- TurnoverNoDraw
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(
				winlostdate
				,username
				,custid
				,roleid
				,recommend
				,mrecommend
				,srecommend
				,turnover
				,winlost
				,awinlost
				,mwinlost
				,swinlost
				,playercomm
				,comm
				,acomm
				,scomm
				,BetCount
				,grosscomm
				,sporttype
				,bettype
				,netTurnover
				,TunroverNoDraw -- TurnoverNoDraw
			)
			VALUES
			(
				SOURCE.winlostdate
				,SOURCE.username
				,SOURCE.custid
				,SOURCE.roleid
				,SOURCE.recommend
				,SOURCE.mrecommend
				,SOURCE.srecommend
				,SOURCE.turnover
				,SOURCE.winlost
				,SOURCE.awinlost
				,SOURCE.mwinlost
				,SOURCE.swinlost
				,SOURCE.playercomm
				,SOURCE.comm
				,SOURCE.acomm
				,SOURCE.scomm
				,SOURCE.BetCount
				,SOURCE.grosscomm
				,SOURCE.sporttype
				,SOURCE.bettype
				,SOURCE.netTurnover
				,SOURCE.TurnoverNoDraw
			)
		WHEN NOT MATCHED BY SOURCE
			AND TARGET.winlostdate = @winlostdate
			AND EXISTS (SELECT 1 FROM #tmpSuper ts WHERE TARGET.srecommend = ts.srecommend)
			THEN DELETE;
	END
	-- End Regen data

	DROP TABLE #tmpSuper
	DROP TABLE #tmpSum_winloss
END
GO