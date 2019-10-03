/*<info serverAlias="DBSUM-bodb_Summary" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_SumWinloss_14]
	@WinlostDate	SMALLDATETIME
	,@CustIds		VARCHAR(MAX)
AS

/*
	Created: 20190909@Percy
	Task: Re-gen data for CS_SumWinloss
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190909@Percy: Initialize SP [RedmineID: #115377]
*/

BEGIN
	SET NOCOUNT ON

	/* ===== Get Customer Info ===== */
	BEGIN
		-- Super
		CREATE TABLE #tmpSuper (srecommend INT)
		INSERT INTO #tmpSuper (srecommend)
		SELECT DISTINCT c.srecommend
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			CROSS APPLY (
				SELECT val FROM bodb02.dbo.strSplit(@CustIds, ',') f WHERE c.custid = f.val
			) AS tmp
		WHERE EXISTS (SELECT 1 FROM bodb02.dbo.CS_CustSuper cs WITH (NOLOCK) WHERE c.srecommend = cs.custid)

		-- Member + SMA
		CREATE TABLE #CustInfo (custid INT, roleid TINYINT)
		INSERT INTO #CustInfo (custid, roleid)
		SELECT c.custid, c.roleid
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			INNER JOIN #tmpSuper s ON c.srecommend = s.srecommend
	END
	/* ===== End Get Customer Info ===== */

	/* ===== Get data ===== */
	BEGIN
		-- bettrans
		CREATE TABLE #tmpBettrans
		(
			srecommend			INT
			,mrecommend			INT
			,recommend			INT
			,custid				INT
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
		
		INSERT INTO #tmpBettrans
		(
			srecommend
			,mrecommend
			,recommend
			,custid
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
			,-SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END) * ISNULL(e.ExtraPT, 0)) AS HeadlineWinloss
			,-SUM((CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.scomm / (1 - b.tpositiontaking) END) * ISNULL(e.ExtraPT, 0)) AS HeadlineComm
			,SUM(ABS(b.winlost - b.actual_stake) * (1 - b.tpositiontaking - ISNULL(e.ExtraPT, 0))) AS HeadlineStock
			,SUM(b.stake * (1 - b.tpositiontaking - ISNULL(e.ExtraPT, 0))) AS HouseTurnover
		FROM #tmpSuper c
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
				FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
					OUTER APPLY (
						SELECT TOP 1 bm.matchid
						FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						WHERE b.refno = bm.refno AND b.bettype = 2799
					) AS s
				WHERE c.srecommend = b.srecommend
					AND b.statusID IN (111, 112, 113)
			) AS b
			CROSS APPLY (
				SELECT TOP 1 sbm.ProductID, sbm.eventtype FROM bodb02.dbo.CS_SportBettypeMatrix sbm WITH (NOLOCK)
				WHERE b.bettype = sbm.bettype
			) AS s
			OUTER APPLY (
				SELECT TOP 1 a.ExtraPT FROM bodb02.dbo.Acc_GroupExtraPTSetting a WITH (NOLOCK)
				WHERE b.srecommend = a.superid AND s.ProductId = a.ProductId AND a.Sporttype = 0 AND a.SubProduct = ''
					AND @WinlostDate BETWEEN a.FromDate AND a.ToDate
			) AS e
		WHERE b.winlostdate = @WinlostDate
		GROUP BY
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,b.matchid
			,s.ProductID
			,b.bettype
			,CASE WHEN b.bettype = 2799 THEN 1 ELSE s.eventtype END
			,b.IsLive

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
			,cs.UplineId
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
				FROM bodb02.dbo.VSRaceInfo r WITH (NOLOCK)
				WHERE b.matchid = r.EventID AND b.eventtype = 3

				UNION ALL
				SELECT CASE WHEN b.matchid = 29 THEN 0 ELSE b.matchid END AS sporttype -- SB Parlay: sporttype = 0
				WHERE b.matchid <> 2799 AND b.eventtype = 0
			) AS m
			CROSS APPLY (SELECT TOP 1 c.UplineId FROM bodb02.dbo.CustSuper c WITH (NOLOCK) WHERE b.srecommend = c.custid) AS cs
		GROUP BY
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,b.ProductId
			,m.Sporttype
			,b.bettype
			,b.IsLive
			,cs.UplineId

		DROP TABLE #tmpBettrans
		DROP TABLE #tmpSuper
	END
	/* ===== End Get data ===== */

	/* ===== Correct Data ===== */
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
		WHEN NOT MATCHED BY SOURCE
			AND TARGET.WinlostDate = @Winlostdate
			AND EXISTS (SELECT 1 FROM #CustInfo c WHERE TARGET.CustId = c.CustId)
			THEN DELETE;
	END
	/* ===== End Correct Data ===== */

	DROP TABLE #tmpSumWinloss
	DROP TABLE #CustInfo
END
GO