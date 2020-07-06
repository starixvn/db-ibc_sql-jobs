/*<info serverAlias="DBSUM-bodb_Summary" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_SumWinloss_CheckAndCorrect]
	@WinlostDate		SMALLDATETIME
	,@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20190809@Percy
	Task: Check and Correct data for CS_SumWinloss
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190809@Percy: Initialize SP [RedmineID: #116925]
		- 20191210@Percy: Apply new column epositiontaking instead of extra PT [RedmineID: #125158]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]
		- 20200212@Percy: Fix wrong get setting from ExtraPT table [RedmineID: #128431]
		- 20200622@Sol: Archive VSRaceInfo - changed to use VSRaceInfo14 [RedmineID: #135963]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @HasMismatch BIT

	/* ===== Get data ===== */
	BEGIN
		-- bettrans
		CREATE TABLE #tmpBettrans
		(
			srecommend			INT
			,mrecommend			INT
			,recommend			INT
			,custid				INT
			,UplineId			INT
			,matchid			INT
			,ProductID			INT
			,bettype			INT
			,eventtype			TINYINT
			,IsLive				BIT
			,Wagers				INT
			,Stake				MONEY
			,ValidStake			MONEY
			,MemberWinloss		MONEY
			,MemberComm			MONEY
			,Agent				MONEY
			,AgentWinloss		MONEY
			,AgentComm			MONEY
			,AgentStock			MONEY
			,AgentResultA		MONEY
			,Master				MONEY
			,MasterWinloss		MONEY
			,MasterComm			MONEY
			,MasterStock		MONEY
			,Super				MONEY
			,SuperWinloss		MONEY
			,SuperComm			MONEY
			,SuperStock			MONEY
			,HeadlineWinloss	MONEY
			,HeadlineComm		MONEY
			,HeadlineStock		MONEY
			,HouseTurnover		MONEY
		)

		-- For VS Parlay (bettype = 2799)
		SELECT b.refno, b.matchid
		INTO #__refno
		FROM bodb02.dbo.CS_CustSuper c WITH (NOLOCK)
			CROSS APPLY (
				SELECT b.refno, bm.matchid
				FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
					CROSS APPLY (SELECT TOP 1 bm.matchid FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK) WHERE b.refno = bm.refno) AS bm
				WHERE c.custid = b.srecommend AND b.matchid = 2799 AND b.winlostdate = @WinlostDate
		) AS b
		
		INSERT INTO #tmpBettrans
		(
			srecommend
			,mrecommend
			,recommend
			,custid
			,UplineId
			,matchid
			,ProductID
			,bettype
			,eventtype
			,IsLive
			,Wagers
			,Stake
			,ValidStake
			,MemberWinloss
			,MemberComm
			,Agent
			,AgentWinloss
			,AgentComm
			,AgentStock
			,AgentResultA
			,Master
			,MasterWinloss
			,MasterComm
			,MasterStock
			,Super
			,SuperWinloss
			,SuperComm
			,SuperStock
			,HeadlineWinloss
			,HeadlineComm
			,HeadlineStock
			,HouseTurnover
		)
		SELECT
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,e.UplineId
			,b.matchid
			,s.ProductID
			,b.bettype
			,CASE WHEN b.bettype = 2799 THEN 1 ELSE s.eventtype END AS eventtype
			,b.IsLive
			,COUNT(1) AS Wagers
			,SUM(b.stake) AS Stake
			,SUM(ABS(b.winlost - b.actual_stake)) AS ValidStake
			,SUM(b.winlost - b.actual_stake) AS MemberWinloss
			,SUM(b.playercomm) AS MemberComm
			,SUM((b.winlost - b.actual_stake)  + (ABS(b.winlost - b.actual_stake) * b.discount)) AS Agent
			,SUM(b.awinlost) AS AgentWinloss
			,SUM(b.comm - b.playercomm) AS AgentComm
			,SUM(ABS(b.winlost - b.actual_stake) * (1 - b.apositiontaking)) AS AgentStock
			,SUM((b.winlost - b.actual_stake + b.playercomm) * (1 - b.apositiontaking)) AS AgentResultA
			,SUM(((b.winlost - b.actual_stake) * (1 - apositiontaking)) + ABS(b.winlost - b.actual_stake) * (1 - b.apositiontaking) * b.adiscount) AS Master
			,SUM(b.mwinlost) AS MasterWinloss
			,SUM(b.acomm - b.comm) AS MasterComm
			,SUM(ABS(b.winlost - b.actual_stake) * (1 - b.apositiontaking - b.mpositiontaking)) AS MasterStock
			,SUM((b.winlost - b.actual_stake) * (1 - b.apositiontaking - b.mpositiontaking)
				+  ABS(b.winlost - b.actual_stake) * (1 - b.apositiontaking - b.mpositiontaking) * b.sdiscount ) AS Super
			,SUM(b.swinlost) AS SuperWinloss
			,SUM(b.scomm - b.acomm) AS SuperComm
			,SUM(ABS(b.winlost - b.actual_stake) * (1 - b.tpositiontaking)) AS SuperStock
			,-SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END) * ISNULL(CONVERT(DECIMAL(9,8), b.epositiontaking), 0)) AS HeadlineWinloss
			,-SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.scomm / (1 - b.tpositiontaking) END) * ISNULL(CONVERT(DECIMAL(9,8), b.epositiontaking), 0)) AS HeadlineComm
			,SUM(ABS(b.winlost - b.actual_stake) * (1 - b.tpositiontaking - ISNULL(CONVERT(DECIMAL(9,8), b.epositiontaking), 0))) AS HeadlineStock
			,SUM(b.stake * (1 - b.tpositiontaking - ISNULL(CONVERT(DECIMAL(9,8), b.epositiontaking), 0))) AS HouseTurnover
		FROM bodb02.dbo.CS_CustSuper c WITH (NOLOCK)
			CROSS APPLY (
				SELECT
					b.srecommend
					,b.mrecommend
					,b.recommend
					,b.custid
					,CASE WHEN b.bettype = 2799 THEN s.matchid ELSE b.matchid END AS matchid
					,b.winlostdate
					,b.bettype
					,CASE WHEN b.bettype = 29 THEN CASE WHEN b.livehomescore = 1 THEN 1 ELSE 0 END ELSE b.liveindicator END AS IsLive
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
					,b.discount
					,b.adiscount
					,b.sdiscount
					,b.apositiontaking
					,b.mpositiontaking
					,b.tpositiontaking
					,b.epositiontaking
				FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
					OUTER APPLY (
						SELECT r.matchid FROM #__refno r WHERE b.refno = r.refno AND b.bettype = 2799
					) AS s
				WHERE c.CustId = b.srecommend
					AND b.statusID IN (111, 112, 113)
			) AS b
			CROSS APPLY (
				SELECT TOP 1 sbm.ProductID, sbm.eventtype FROM bodb02.dbo.CS_SportBettypeMatrix sbm WITH (NOLOCK)
				WHERE b.bettype = sbm.bettype
			) AS s
			CROSS APPLY (
				SELECT TOP 1 a.UplineId
				FROM bodb02.dbo.Acc_GroupExtraPTSetting a WITH (NOLOCK)
				WHERE b.srecommend = a.SuperId
					AND a.ProductId = 1
					AND a.Sporttype = 0
					AND a.SubProduct = ''
					AND @WinlostDate BETWEEN a.FromDate AND a.ToDate
			) AS e
		WHERE b.winlostdate = @WinlostDate
		GROUP BY
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,e.UplineId
			,b.matchid
			,s.ProductID
			,b.bettype
			,CASE WHEN b.bettype = 2799 THEN 1 ELSE s.eventtype END
			,b.IsLive

		DROP TABLE #__refno

		-- Sum data
		CREATE TABLE #tmpSumWinloss
		(
			srecommend			INT
			,mrecommend			INT
			,recommend			INT
			,custid				INT
			,ProductId			SMALLINT
			,Sporttype			SMALLINT
			,Bettype			SMALLINT
			,IsLive				BIT
			,Wagers				INT
			,Stake				MONEY
			,ValidStake			MONEY
			,MemberWinloss		MONEY
			,MemberComm			MONEY
			,Agent				MONEY
			,AgentWinloss		MONEY
			,AgentComm			MONEY
			,AgentStock			MONEY
			,AgentResultA		MONEY
			,Master				MONEY
			,MasterWinloss		MONEY
			,MasterComm			MONEY
			,MasterStock		MONEY
			,Super				MONEY
			,SuperWinloss		MONEY
			,SuperComm			MONEY
			,SuperStock			MONEY
			,HeadlineWinloss	MONEY
			,HeadlineComm		MONEY
			,HeadlineStock		MONEY
			,HeadlineId			INT
			,HouseTurnover		MONEY
		)

		INSERT INTO #tmpSumWinloss
		(
			srecommend
			,mrecommend
			,recommend
			,custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,Wagers
			,Stake
			,ValidStake
			,MemberWinloss
			,MemberComm
			,Agent
			,AgentWinloss
			,AgentComm
			,AgentStock
			,AgentResultA
			,Master
			,MasterWinloss
			,MasterComm
			,MasterStock
			,Super
			,SuperWinloss
			,SuperComm
			,SuperStock
			,HeadlineWinloss
			,HeadlineComm
			,HeadlineStock
			,HeadlineId
			,HouseTurnover
		)
		SELECT
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,b.ProductId
			,m.Sporttype
			,b.bettype
			,b.IsLive
			,SUM(b.Wagers)			AS Wagers
			,SUM(b.Stake)			AS Stake
			,SUM(b.ValidStake)		AS ValidStake
			,SUM(b.MemberWinloss)	AS MemberWinloss
			,SUM(b.MemberComm)		AS MemberComm
			,SUM(b.Agent)			AS Agent
			,SUM(b.AgentWinloss)	AS AgentWinloss
			,SUM(b.AgentComm)		AS AgentComm
			,SUM(b.AgentStock)		AS AgentStock
			,SUM(b.AgentResultA)	AS AgentResultA
			,SUM(b.Master)			AS Master
			,SUM(b.MasterWinloss)	AS MasterWinloss
			,SUM(b.MasterComm)		AS MasterComm
			,SUM(b.MasterStock)		AS MasterStock
			,SUM(b.Super)			AS Super
			,SUM(b.SuperWinloss)	AS SuperWinloss
			,SUM(b.SuperComm)		AS SuperComm
			,SUM(b.SuperStock)		AS SuperStock
			,SUM(b.HeadlineWinloss)	AS HeadlineWinloss
			,SUM(b.HeadlineComm)	AS HeadlineComm
			,SUM(b.HeadlineStock)	AS HeadlineStock
			,b.UplineId
			,SUM(b.HouseTurnover)	AS HouseTurnover
		FROM #tmpBettrans b
			CROSS APPLY (
				SELECT m.sporttype
				FROM bodb02.dbo.match14 m WITH (NOLOCK)
				WHERE b.matchid = m.matchid AND b.eventtype = 1 -- included Betradar VS Parlay

				UNION ALL
				SELECT l.sporttype
				FROM bodb02.dbo.outright14 o WITH (NOLOCK)
					INNER JOIN bodb02.dbo.League l WITH (NOLOCK) ON o.leagueid = l.leagueid
				WHERE b.matchid = o.orid AND b.eventtype = 2

				UNION ALL
				SELECT r.sporttype
				FROM bodb02.dbo.VSRaceInfo14 r WITH (NOLOCK)
				WHERE b.matchid = r.EventID AND b.eventtype = 3

				UNION ALL
				SELECT CASE WHEN b.matchid = 29 THEN 0 ELSE b.matchid END AS sporttype -- SB Parlay: sporttype = 0
				WHERE b.matchid <> 2799 AND b.eventtype = 0
			) AS m
		GROUP BY
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,b.ProductId
			,m.Sporttype
			,b.bettype
			,b.IsLive
			,b.UplineId

		DROP TABLE #tmpBettrans
	END
	/* ===== End Get data ===== */

	/* ===== Check and Correct Data ===== */
	BEGIN
		DECLARE @RowCount INT

		;WITH CTE_CS_SumWinloss AS (
			SELECT
				s.custid
				,s.ProductId
				,s.Sporttype
				,s.bettype
				,s.IsLive
				,s.Wagers
				,s.Stake
				,s.ValidStake
				,s.MemberWinloss
				,s.MemberComm
				,s.Agent
				,s.AgentWinloss
				,s.AgentComm
				,s.AgentStock
				,s.AgentResultA
				,s.Master
				,s.MasterWinloss
				,s.MasterComm
				,s.MasterStock
				,s.Super
				,s.SuperWinloss
				,s.SuperComm
				,s.SuperStock
				,s.HeadlineWinloss
				,s.HeadlineComm
				,s.HeadlineStock
				,s.HeadlineId
				,s.HouseTurnover
			FROM dbo.CS_SumWinloss s WITH (NOLOCK)
			WHERE s.WinlostDate	= @WinlostDate
				AND EXISTS (SELECT 1 FROM bodb02.dbo.custInfo c WITH (NOLOCK) WHERE s.custid = c.custid AND c.roleid = 1)
		)
		SELECT @RowCount = COUNT(1)
		FROM CTE_CS_SumWinloss s
			FULL OUTER JOIN #tmpSumWinloss t
				ON		s.custid		= t.custid
					AND s.ProductId		= t.ProductId
					AND s.Sporttype		= t.Sporttype
					AND s.bettype		= t.bettype
					AND s.IsLive		= t.IsLive
		WHERE s.custid IS NULL
			OR t.custid IS NULL
			OR s.Wagers				<> t.Wagers
			OR s.Stake				<> t.Stake
			OR s.ValidStake			<> t.ValidStake
			OR s.MemberWinloss		<> t.MemberWinloss
			OR s.MemberComm			<> t.MemberComm
			OR s.Agent				<> t.Agent
			OR s.AgentWinloss		<> t.AgentWinloss
			OR s.AgentComm			<> t.AgentComm
			OR s.AgentStock			<> t.AgentStock
			OR s.AgentResultA		<> t.AgentResultA
			OR s.Master				<> t.Master
			OR s.MasterWinloss		<> t.MasterWinloss
			OR s.MasterComm			<> t.MasterComm
			OR s.MasterStock		<> t.MasterStock
			OR s.Super				<> t.Super
			OR s.SuperWinloss		<> t.SuperWinloss
			OR s.SuperComm			<> t.SuperComm
			OR s.SuperStock			<> t.SuperStock
			OR s.HeadlineWinloss	<> t.HeadlineWinloss
			OR s.HeadlineComm		<> t.HeadlineComm
			OR s.HeadlineStock		<> t.HeadlineStock
			OR s.HeadlineId			<> t.HeadlineId
			OR s.HouseTurnover		<> t.HouseTurnover
		
		IF @RowCount <> 0
			SELECT @HasMismatch = 1
		ELSE
			SELECT @HasMismatch = 0

		IF @HasMismatch = 0
			RETURN

		IF @IsCheckDataOnly = 1
		BEGIN
			;WITH CTE_CS_SumWinloss AS (
				SELECT
					s.custid
					,s.ProductId
					,s.Sporttype
					,s.bettype
					,s.IsLive
					,s.Wagers
					,s.Stake
					,s.ValidStake
					,s.MemberWinloss
					,s.MemberComm
					,s.Agent
					,s.AgentWinloss
					,s.AgentComm
					,s.AgentStock
					,s.AgentResultA
					,s.Master
					,s.MasterWinloss
					,s.MasterComm
					,s.MasterStock
					,s.Super
					,s.SuperWinloss
					,s.SuperComm
					,s.SuperStock
					,s.HeadlineWinloss
					,s.HeadlineComm
					,s.HeadlineStock
					,s.HeadlineId
					,s.HouseTurnover
				FROM dbo.CS_SumWinloss s WITH (NOLOCK)
				WHERE s.WinlostDate	= @WinlostDate
					AND EXISTS (SELECT 1 FROM bodb02.dbo.custInfo c WITH (NOLOCK) WHERE s.custid = c.custid AND c.roleid = 1)
			)
			SELECT 'Check Member Only'					AS DataSource
					,ISNULL(s.custid, t.custid)			AS custid
					,ISNULL(s.ProductId, t.ProductId)	AS ProductId
					,ISNULL(s.Sporttype, t.Sporttype)	AS Sporttype
					,ISNULL(s.bettype, t.bettype)		AS bettype
					,ISNULL(s.IsLive, t.IsLive)			AS IsLive
			FROM CTE_CS_SumWinloss s
				FULL OUTER JOIN #tmpSumWinloss t
					ON		s.custid		= t.custid
						AND s.ProductId		= t.ProductId
						AND s.Sporttype		= t.Sporttype
						AND s.bettype		= t.bettype
						AND s.IsLive		= t.IsLive
			WHERE s.custid IS NULL
				OR t.custid IS NULL
				OR s.Wagers				<> t.Wagers
				OR s.Stake				<> t.Stake
				OR s.ValidStake			<> t.ValidStake
				OR s.MemberWinloss		<> t.MemberWinloss
				OR s.MemberComm			<> t.MemberComm
				OR s.Agent				<> t.Agent
				OR s.AgentWinloss		<> t.AgentWinloss
				OR s.AgentComm			<> t.AgentComm
				OR s.AgentStock			<> t.AgentStock
				OR s.AgentResultA		<> t.AgentResultA
				OR s.Master				<> t.Master
				OR s.MasterWinloss		<> t.MasterWinloss
				OR s.MasterComm			<> t.MasterComm
				OR s.MasterStock		<> t.MasterStock
				OR s.Super				<> t.Super
				OR s.SuperWinloss		<> t.SuperWinloss
				OR s.SuperComm			<> t.SuperComm
				OR s.SuperStock			<> t.SuperStock
				OR s.HeadlineWinloss	<> t.HeadlineWinloss
				OR s.HeadlineComm		<> t.HeadlineComm
				OR s.HeadlineStock		<> t.HeadlineStock
				OR s.HeadlineId			<> t.HeadlineId
				OR s.HouseTurnover		<> t.HouseTurnover
		END
		ELSE
		BEGIN
			-- Sum for SMA
			INSERT INTO #tmpSumWinloss
			(
				custid
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,Wagers
				,Stake
				,ValidStake
				,MemberWinloss
				,MemberComm
				,Agent
				,AgentWinloss
				,AgentComm
				,AgentStock
				,AgentResultA
				,Master
				,MasterWinloss
				,MasterComm
				,MasterStock
				,Super
				,SuperWinloss
				,SuperComm
				,SuperStock
				,HeadlineWinloss
				,HeadlineComm
				,HeadlineStock
				,HeadlineId
				,HouseTurnover
			)
			SELECT
				recommend AS custid
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,SUM(Wagers)			AS Wagers
				,SUM(Stake)				AS Stake
				,SUM(ValidStake)		AS ValidStake
				,SUM(MemberWinloss)		AS MemberWinloss
				,SUM(MemberComm)		AS MemberComm
				,SUM(Agent)				AS Agent
				,SUM(AgentWinloss)		AS AgentWinloss
				,SUM(AgentComm)			AS AgentComm
				,SUM(AgentStock)		AS AgentStock
				,SUM(AgentResultA)		AS AgentResultA
				,SUM(Master)			AS Master
				,SUM(MasterWinloss)		AS MasterWinloss
				,SUM(MasterComm)		AS MasterComm
				,SUM(MasterStock)		AS MasterStock
				,SUM(Super)				AS Super
				,SUM(SuperWinloss)		AS SuperWinloss
				,SUM(SuperComm)			AS SuperComm
				,SUM(SuperStock)		AS SuperStock
				,SUM(HeadlineWinloss)	AS HeadlineWinloss
				,SUM(HeadlineComm)		AS HeadlineComm
				,SUM(HeadlineStock)		AS HeadlineStock
				,HeadlineId
				,SUM(HouseTurnover)		AS HouseTurnover
			FROM #tmpSumWinloss
			GROUP BY
				recommend
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,HeadlineId

			UNION ALL
			SELECT
				mrecommend AS custid
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,SUM(Wagers)			AS Wagers
				,SUM(Stake)				AS Stake
				,SUM(ValidStake)		AS ValidStake
				,SUM(MemberWinloss)		AS MemberWinloss
				,SUM(MemberComm)		AS MemberComm
				,SUM(Agent)				AS Agent
				,SUM(AgentWinloss)		AS AgentWinloss
				,SUM(AgentComm)			AS AgentComm
				,SUM(AgentStock)		AS AgentStock
				,SUM(AgentResultA)		AS AgentResultA
				,SUM(Master)			AS Master
				,SUM(MasterWinloss)		AS MasterWinloss
				,SUM(MasterComm)		AS MasterComm
				,SUM(MasterStock)		AS MasterStock
				,SUM(Super)				AS Super
				,SUM(SuperWinloss)		AS SuperWinloss
				,SUM(SuperComm)			AS SuperComm
				,SUM(SuperStock)		AS SuperStock
				,SUM(HeadlineWinloss)	AS HeadlineWinloss
				,SUM(HeadlineComm)		AS HeadlineComm
				,SUM(HeadlineStock)		AS HeadlineStock
				,HeadlineId
				,SUM(HouseTurnover)		AS HouseTurnover
			FROM #tmpSumWinloss
			GROUP BY
				mrecommend
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,HeadlineId

			UNION ALL
			SELECT
				srecommend AS custid
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,SUM(Wagers)			AS Wagers
				,SUM(Stake)				AS Stake
				,SUM(ValidStake)		AS ValidStake
				,SUM(MemberWinloss)		AS MemberWinloss
				,SUM(MemberComm)		AS MemberComm
				,SUM(Agent)				AS Agent
				,SUM(AgentWinloss)		AS AgentWinloss
				,SUM(AgentComm)			AS AgentComm
				,SUM(AgentStock)		AS AgentStock
				,SUM(AgentResultA)		AS AgentResultA
				,SUM(Master)			AS Master
				,SUM(MasterWinloss)		AS MasterWinloss
				,SUM(MasterComm)		AS MasterComm
				,SUM(MasterStock)		AS MasterStock
				,SUM(Super)				AS Super
				,SUM(SuperWinloss)		AS SuperWinloss
				,SUM(SuperComm)			AS SuperComm
				,SUM(SuperStock)		AS SuperStock
				,SUM(HeadlineWinloss)	AS HeadlineWinloss
				,SUM(HeadlineComm)		AS HeadlineComm
				,SUM(HeadlineStock)		AS HeadlineStock
				,HeadlineId
				,SUM(HouseTurnover)		AS HouseTurnover
			FROM #tmpSumWinloss
			GROUP BY
				srecommend
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,HeadlineId

			-- Correct Data
			;MERGE dbo.CS_SumWinloss AS TARGET
			USING #tmpSumWinloss AS SOURCE
				ON		TARGET.WinlostDate	= @WinlostDate
					AND TARGET.custid		= SOURCE.custid
					AND TARGET.ProductId	= SOURCE.ProductId
					AND TARGET.Sporttype	= SOURCE.Sporttype
					AND TARGET.Bettype		= SOURCE.Bettype
					AND TARGET.IsLive		= SOURCE.IsLive
			WHEN MATCHED THEN UPDATE SET
					TARGET.Wagers			= SOURCE.Wagers
					,TARGET.Stake			= SOURCE.Stake
					,TARGET.ValidStake		= SOURCE.ValidStake
					,TARGET.MemberWinloss	= SOURCE.MemberWinloss
					,TARGET.MemberComm		= SOURCE.MemberComm
					,TARGET.Agent			= SOURCE.Agent
					,TARGET.AgentWinloss	= SOURCE.AgentWinloss
					,TARGET.AgentComm		= SOURCE.AgentComm
					,TARGET.AgentStock		= SOURCE.AgentStock
					,TARGET.AgentResultA	= SOURCE.AgentResultA
					,TARGET.Master			= SOURCE.Master
					,TARGET.MasterWinloss	= SOURCE.MasterWinloss
					,TARGET.MasterComm		= SOURCE.MasterComm
					,TARGET.MasterStock		= SOURCE.MasterStock
					,TARGET.Super			= SOURCE.Super
					,TARGET.SuperWinloss	= SOURCE.SuperWinloss
					,TARGET.SuperComm		= SOURCE.SuperComm
					,TARGET.SuperStock		= SOURCE.SuperStock
					,TARGET.HeadlineWinloss	= SOURCE.HeadlineWinloss
					,TARGET.HeadlineComm	= SOURCE.HeadlineComm
					,TARGET.HeadlineStock	= SOURCE.HeadlineStock
					,TARGET.HeadlineId		= SOURCE.HeadlineId
					,TARGET.HouseTurnover	= SOURCE.HouseTurnover
			WHEN NOT MATCHED BY TARGET THEN INSERT
				(
					WinlostDate
					,CustId
					,ProductID
					,Sporttype
					,Bettype
					,IsLive
					,Wagers
					,Stake
					,ValidStake
					,MemberWinloss
					,MemberComm
					,Agent
					,AgentWinloss
					,AgentComm
					,AgentStock
					,AgentResultA
					,Master
					,MasterWinloss
					,MasterComm
					,MasterStock
					,Super
					,SuperWinloss
					,SuperComm
					,SuperStock
					,HeadlineWinloss
					,HeadlineComm
					,HeadlineStock
					,HeadlineId
					,HouseTurnover
				)
				VALUES
				(
					@WinlostDate
					,SOURCE.CustId
					,SOURCE.ProductID
					,SOURCE.Sporttype
					,SOURCE.Bettype
					,SOURCE.IsLive
					,SOURCE.Wagers
					,SOURCE.Stake
					,SOURCE.ValidStake
					,SOURCE.MemberWinloss
					,SOURCE.MemberComm
					,SOURCE.Agent
					,SOURCE.AgentWinloss
					,SOURCE.AgentComm
					,SOURCE.AgentStock
					,SOURCE.AgentResultA
					,SOURCE.Master
					,SOURCE.MasterWinloss
					,SOURCE.MasterComm
					,SOURCE.MasterStock
					,SOURCE.Super
					,SOURCE.SuperWinloss
					,SOURCE.SuperComm
					,SOURCE.SuperStock
					,SOURCE.HeadlineWinloss
					,SOURCE.HeadlineComm
					,SOURCE.HeadlineStock
					,SOURCE.HeadlineId
					,SOURCE.HouseTurnover
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN DELETE;
		END
	END
	/* ===== End Check and Correct Data ===== */

	DROP TABLE #tmpSumWinloss
END
GO