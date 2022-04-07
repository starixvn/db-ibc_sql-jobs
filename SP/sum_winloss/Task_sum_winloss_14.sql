/*<info serverAlias="DBTXN-bodb02" isNested="1"></info>*/
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
		- 20200410@Sophia: Add BBIN, Sexy Gaming, SA Gaming [RedmineId: #131358]
		- 20200422@Sophia: Add IBCBet Live Casino [RedmineId: #130693]
		- 20200527@Sophia: Add ION [Redmine: #132325]
		- 20200528@Sophia: Add RNG War [Redmine: #132013]
		- 20200708@Sol: Generate data for sum_winloss table - Redmine: [#136320]
		- 20200820@Sol: enhence performance when statistics are not updated yet - Redmine: [#136320]
		- 20200910@Malcolm: Report Enhancement for Jackpot Product [RedmineID : #139575]
		- 20200915@Malcolm: Add WM Live Casino [redmine: #131584]
		- 20201201@Malcolm: Add Gold Diamond Gaming [Redmine : #144110]
		- 20201210@Malcolm: Add Big Gaming [RedmineId : #142459]
		- 20210310@Malcolm: Add Pragmatic Live Casino [RedmineId : #133717]
		- 20210609@Malcolm: Add AE Sexy - [Redmine: #156239]	
		- 20210617@Sol: changed how to calc net turn over - [RedmineId : #156653]
		- 20211122@Percy: Enhance gross comm formula [RedmineID: #164479]
		- 20220106@Evan: Add SG Jackpot - [Redmine: #166685]	
		- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
*/

BEGIN
	SET NOCOUNT ON

	-- Get Bet Types
	DECLARE @ProductIds VARCHAR(MAX)
	SELECT  @ProductIds = COALESCE(@ProductIds + ',', '') + CONVERT(VARCHAR(10), ProductId) FROM dbo.Products WITH (NOLOCK)

	DECLARE @NetTO_CutOffDate SMALLDATETIME, @GrossComm_CutOffDate SMALLDATETIME

	SELECT  @NetTO_CutOffDate = CASE WHEN f.TypeName = 'NetTO' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@GrossComm_CutOffDate = CASE WHEN f.TypeName = 'GrossComm' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
	FROM dbo.f_GetCutOffDate() f
	WHERE f.TypeName IN ('NetTO', 'GrossComm')

	CREATE TABLE #Bettypes (ProductId INT, SportTypeRef SMALLINT, BettypeRef SMALLINT, Bettype SMALLINT, RefTable TINYINT, IsContributionBettype BIT)
	INSERT INTO #Bettypes (ProductId, SportTypeRef, BettypeRef, Bettype, RefTable, IsContributionBettype)
	SELECT f.ProductID, f.SportType AS SportTypeRef, f.BetType AS BettypeRef, s.BetType, s.RefTable
		,CASE WHEN cont.Bettype IS NOT NULL THEN 1 ELSE 0 END AS IsContributionBettype
	FROM dbo.f_SumWinloss_ConditionSel(@ProductIds) f
		CROSS APPLY (
			SELECT DISTINCT s.RefTable, s.BetType FROM dbo.SportBettypeMatrix s WITH (NOLOCK)
			WHERE f.ProductID = s.ProductID
				AND (f.ProductID <> 6 OR f.SportType = s.SportType)
				AND (f.BetType NOT IN (3150, 4297, 4298, 4599, 4600) AND s.BetType NOT IN (3150, 4297, 4298, 4599, 4600) OR f.BetType = s.BetType)
		) AS s
		OUTER APPLY 
		(
			SELECT t.Bettype
			FROM dbo.f_BettypePrizeGroup() t
			WHERE t.BettypeGroup = 'Contribution'
				AND t.Bettype = s.bettype
		) cont
	-- End Get Bet Types

	-- Get Customer Info
	BEGIN
		-- Super
		CREATE TABLE #tmpSuper (srecommend INT)
		INSERT INTO #tmpSuper (srecommend)
		SELECT DISTINCT c.srecommend
		FROM CustDB.dbo.Customer c WITH (NOLOCK)
			CROSS APPLY (
				SELECT value FROM STRING_SPLIT(@CustIds, ',') f WHERE c.custid = f.value
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

	---- temp table to get data Net TO, Gross Comm from bettransRnG/bettransLC
	CREATE TABLE #__NetTO_GrossComm (custid INT, sporttype SMALLINT, bettype SMALLINT, TurnoverNoDraw MONEY, grosscomm MONEY, agrosscomm MONEY, mgrosscomm MONEY, sgrosscomm MONEY)
	
	---- get extra PT from table setting
	CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY)
	CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT)
	
	;WITH rs AS 
	(
		SELECT DISTINCT b.bettype , b.srecommend
		FROM bettrans14 b WITH(NOLOCK) 
			INNER JOIN #tmpSuper s
				ON s.srecommend = b.srecommend
		WHERE 
			b.winlostdate = @winlostdate
			AND b.statusID IN (111,112,113)
			AND b.bettype <= 19000
	)
	INSERT INTO #__SuperExtraPT (productId, bettypePT, SuperId, ExtraPT)
	SELECT tbl.ProductID, b.bettype , b.srecommend , T.ExtraPT
	FROM rs b 
		CROSS APPLY 
		(
			SELECT
				tbl.ProductID
			FROM f_SportBettypeMatrix_Sel(0, 0, b.bettype, 2, '', '', 0) tbl
			WHERE b.bettype = tbl.bettype
		) tbl
		OUTER APPLY 
		(
			SELECT expt2.SuperId, expt2.ExtraPT
			FROM CustDB.dbo.Acc_GroupExtraPT2Setting expt2 WITH (NOLOCK)
			WHERE @winlostdate BETWEEN expt2.FromDate AND expt2.ToDate
					AND tbl.ProductID = expt2.ProductID
					AND b.srecommend = expt2.SuperId 
					AND ISNULL(expt2.SubProduct,'') = ''
					AND expt2.Sporttype = 0
		) t

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
			,ExtraWinloss		MONEY NULL
			,ExtraComm			MONEY NULL
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
			,ExtraWinloss
			,ExtraComm
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
			,SUM(CASE	WHEN bt.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
						WHEN b.apositiontaking = 1 THEN 0
						ELSE ISNULL(b.comm / (1 - b.apositiontaking), 0) END) AS member_grosscomm
			,SUM(CASE	WHEN bt.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
						WHEN b.apositiontaking + b.mpositiontaking = 1 THEN 0
						ELSE ISNULL(b.acomm / (1 - b.apositiontaking - b.mpositiontaking), 0) END) AS agent_grosscomm
			,SUM(CASE	WHEN bt.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
						WHEN b.tpositiontaking = 1 THEN 0
						ELSE ISNULL(b.scomm / (1 - b.tpositiontaking), 0) END) AS master_grosscomm
			,SUM(CASE	WHEN bt.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
						WHEN b.tpositiontaking = 1 THEN 0
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
					WHEN b.winlostdate < @NetTO_CutOffDate AND bt.ProductId IN (21, 39, 45, 46, 47, 51 ,52, 57, 59, 65) THEN b.oddsspread
					WHEN bt.ProductId = 47 THEN b.oddsspread -- BBIN
					WHEN bt.RefTable IN (1, 2) AND b.winlostdate >= @GrossComm_CutOffDate THEN 0
					WHEN bt.RefTable IN (1, 2) AND b.winlostdate >= @NetTO_CutOffDate THEN
						CASE WHEN bt.IsContributionBettype = 0 THEN b.oddsspread ELSE 0 END
					ELSE ABS(b.stake) END) AS TurnoverNoDraw
			,-1 * SUM(ISNULL(b.ExtraWinloss, 0)) AS ExtraWinloss
			,-1 * SUM(ISNULL(b.ExtraComm, 0)) AS ExtraComm
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
					,CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998, 4297, 4599) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999, 4298, 4600) THEN 0
						ELSE CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(b.epositiontaking, 0)
						END 
					AS ExtraWinloss,
					CASE 
						/*IBCBet Live Casino*/
						WHEN b.bettype BETWEEN 3201 AND 3299 THEN b.scomm
						WHEN b.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 4599, 4600) THEN 0
						ELSE 
							CASE 
								WHEN b.tpositiontaking = 1 THEN 0 
								ELSE b.scomm / (1 - b.tpositiontaking)
							END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(b.epositiontaking, 0) END 
					END
					AS ExtraComm
				FROM dbo.bettrans14 b WITH (NOLOCK)
					INNER JOIN #__SuperExtraPT tbl 
						ON b.srecommend = tbl.SuperId
							AND b.bettype = tbl.bettypePT
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

		-- Update Gross Comm / Net Turnover
		IF @winlostdate >= @GrossComm_CutOffDate
		BEGIN
			INSERT INTO #__NetTO_GrossComm (custid, sporttype, bettype, TurnoverNoDraw, grosscomm, agrosscomm, mgrosscomm, sgrosscomm)
			SELECT c.custid, bt.SporttypeRef, bt.BettypeRef
				,SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.BetStake ELSE 0 END) AS TurnoverNoDraw
				,SUM(b.BetStake * discount) grosscomm
				,SUM(b.BetStake * adiscount) agrosscomm
				,SUM(b.BetStake * sdiscount) mgrosscomm
				,SUM(b.BetStake * sdiscount) sgrosscomm
			FROM #tmpCust c
				CROSS APPLY (
					SELECT b.gameID, b.BetStake, b.discount, b.adiscount, b.sdiscount
					FROM dbo.bettransRnG14 b WITH (NOLOCK)
					WHERE b.winlostdate = @WinlostDate
						AND c.custid = b.custid
						AND b.statusID IN (111,112,113)
				) b
				INNER JOIN #Bettypes bt ON b.gameID = bt.bettype
			GROUP BY c.custid, bt.SporttypeRef, bt.BettypeRef
			HAVING SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.BetStake ELSE 0 END) <> 0
				OR SUM(b.BetStake * discount) <> 0
				OR SUM(b.BetStake * adiscount) <> 0
				OR SUM(b.BetStake * sdiscount) <> 0

			INSERT INTO #__NetTO_GrossComm (custid, sporttype, bettype, TurnoverNoDraw, grosscomm, agrosscomm, mgrosscomm, sgrosscomm)
			SELECT c.custid, bt.SporttypeRef, bt.BettypeRef
				,SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.NetStake ELSE 0 END) AS TurnoverNoDraw
				,SUM(b.NetStake * discount) grosscomm
				,SUM(b.NetStake * adiscount) agrosscomm
				,SUM(b.NetStake * sdiscount) mgrosscomm
				,SUM(b.NetStake * sdiscount) sgrosscomm
			FROM #tmpCust c
				CROSS APPLY (
					SELECT b.gameID, b.NetStake, b.discount, b.adiscount, b.sdiscount
					FROM dbo.bettransLC14 b WITH (NOLOCK)
					WHERE b.winlostdate = @WinlostDate
						AND c.custid = b.custid
						AND b.statusID IN (111,112,113)
				) b
				INNER JOIN #Bettypes bt ON b.gameID = bt.bettype
			GROUP BY c.custid, bt.SporttypeRef, bt.BettypeRef
			HAVING SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.NetStake ELSE 0 END) <> 0
				OR SUM(b.NetStake * discount) <> 0
				OR SUM(b.NetStake * adiscount) <> 0
				OR SUM(b.NetStake * sdiscount) <> 0

			UPDATE t
			SET t.TurnoverNoDraw = ISNULL(c.TurnoverNoDraw, 0)
				,t.member_grosscomm = ISNULL(c.grosscomm, 0)
				,t.agent_grosscomm = ISNULL(c.agrosscomm, 0)
				,t.master_grosscomm = ISNULL(c.mgrosscomm, 0)
				,t.super_grosscomm = ISNULL(c.sgrosscomm, 0)
			FROM #tmpBettrans t
				INNER JOIN #__NetTO_GrossComm c ON t.custid = c.custid AND t.sporttype = c.sporttype and t.bettype = c.bettype
		END
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
			,ExtraWinloss		MONEY NULL
			,ExtraComm			MONEY NULL
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
			,ExtraWinloss
			,ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
				,SUM(ExtraWinloss) AS ExtraWinloss
				,SUM(ExtraComm) AS ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
				,SUM(ExtraWinloss) AS ExtraWinloss
				,SUM(ExtraComm) AS ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
				,SUM(ExtraWinloss) AS ExtraWinloss
				,SUM(ExtraComm) AS ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
			,ExtraWinloss
			,ExtraComm
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
				,ISNULL(ExtraWinloss, 0) AS ExtraWinloss
				,ISNULL(ExtraComm, 0) AS ExtraComm
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
			OR tmp.ExtraWinloss			<> s.ExtraWinloss
			OR tmp.ExtraComm			<> s.ExtraComm
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
				,TARGET.ExtraWinloss	= SOURCE.ExtraWinloss
				,TARGET.ExtraComm		= SOURCE.ExtraComm
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
				,ExtraWinloss
				,ExtraComm
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
				,SOURCE.ExtraWinloss
				,SOURCE.ExtraComm
			)
		WHEN NOT MATCHED BY SOURCE
			AND TARGET.winlostdate = @winlostdate
			AND EXISTS (SELECT 1 FROM #tmpSuper ts WHERE TARGET.srecommend = ts.srecommend)
			THEN DELETE;
	END
	-- End Regen data

	DROP TABLE #tmpSuper
	DROP TABLE #tmpSum_winloss
	DROP TABLE #__SuperExtraPT
	DROP TABLE #__NetTO_GrossComm
END
GO