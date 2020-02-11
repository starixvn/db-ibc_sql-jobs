/*<info serverAlias="DBSUM-bodb_Summary" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_SumCancelled_14]
	@WinlostDate SMALLDATETIME
	,@CustIds		VARCHAR(MAX)
AS

/*
	Created: 20190809@Percy
	Task: Gen data for CS_SumCancelled
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190809@Percy: Initialize SP [RedmineID: #116925]
		- 20191210@Percy: Add HouseTurnover [RedmineID: #125186]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]
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
			srecommend		INT
			,mrecommend		INT
			,recommend		INT
			,custid			INT
			,UplineId	INT
			,matchid		INT
			,ProductID		INT
			,bettype		INT
			,eventtype		TINYINT
			,IsLive			BIT
			,CancelType		TINYINT
			,Wagers			INT
			,Stake			MONEY
			,HouseTurnover	MONEY
		)

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
			,CancelType
			,Wagers
			,Stake
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
			,b.CancelType
			,COUNT(1) AS Wagers
			,SUM(b.stake) AS Stake
			,SUM(b.stake * (1 - b.tpositiontaking - ISNULL(CONVERT(DECIMAL(9,8), b.epositiontaking), 0))) AS HouseTurnover
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
					,CASE WHEN b.ExtraInfo LIKE '%p1%' AND t.c = 1 THEN 2 ELSE 1 END AS CancelType
					,b.stake
					,b.tpositiontaking
					,b.epositiontaking
				FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
					OUTER APPLY (
						SELECT TOP 1 bm.matchid
						FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						WHERE b.refno = bm.refno AND b.bettype = 2799
					) AS s
					OUTER APPLY (SELECT CAST(('<xml>' + ISNULL(b.ExtraInfo, '') + '</xml>') AS XML).value('data(/xml/p1/@ab)[1]','TINYINT')) AS t(c)
				WHERE c.srecommend = b.srecommend
					AND b.statusID IN (101, 102, 103)
			) AS b
			CROSS APPLY (SELECT TOP 1 sbm.ProductID, sbm.eventtype FROM bodb02.dbo.CS_SportBettypeMatrix sbm WITH (NOLOCK) WHERE b.bettype = sbm.bettype) AS s
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
			,b.CancelType

		-- Sum data
		CREATE TABLE #tmpSumCancelled
		(
			srecommend		INT
			,mrecommend		INT
			,recommend		INT
			,custid			INT
			,ProductId		SMALLINT
			,Sporttype		SMALLINT
			,Bettype		SMALLINT
			,IsLive			BIT
			,CancelType		TINYINT
			,Wagers			INT
			,Stake			MONEY
			,HouseTurnover	MONEY
			,HeadlineId		INT
		)

		INSERT INTO #tmpSumCancelled
		(
			srecommend
			,mrecommend
			,recommend
			,custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,Wagers
			,Stake
			,HouseTurnover
			,HeadlineId
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
			,b.CancelType
			,SUM(b.Wagers)			AS Wagers
			,SUM(b.Stake)			AS Stake
			,SUM(b.HouseTurnover)	AS HouseTurnover
			,b.UplineId
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
		GROUP BY
			b.srecommend
			,b.mrecommend
			,b.recommend
			,b.custid
			,b.ProductId
			,m.Sporttype
			,b.bettype
			,b.IsLive
			,b.CancelType
			,b.UplineId

		DROP TABLE #tmpBettrans
		DROP TABLE #tmpSuper
	END
	/* ===== End Get data ===== */

	/* ===== Check and Correct Data ===== */
	BEGIN
		-- Sum for SMA
		INSERT INTO #tmpSumCancelled
		(
			custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,Wagers
			,Stake
			,HouseTurnover
			,HeadlineId
		)
		SELECT
			recommend AS custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,SUM(Wagers)		AS Wagers
			,SUM(Stake)			AS Stake
			,SUM(HouseTurnover)	AS HouseTurnover
			,HeadlineId
		FROM #tmpSumCancelled
		GROUP BY
			recommend
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,HeadlineId

		UNION ALL
		SELECT
			mrecommend AS custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,SUM(Wagers)		AS Wagers
			,SUM(Stake)			AS Stake
			,SUM(HouseTurnover)	AS HouseTurnover
			,HeadlineId
		FROM #tmpSumCancelled
		GROUP BY
			mrecommend
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,HeadlineId

		UNION ALL
		SELECT
			srecommend AS custid
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,SUM(Wagers)		AS Wagers
			,SUM(Stake)			AS Stake
			,SUM(HouseTurnover)	AS HouseTurnover
			,HeadlineId
		FROM #tmpSumCancelled
		GROUP BY
			srecommend
			,ProductId
			,Sporttype
			,Bettype
			,IsLive
			,CancelType
			,HeadlineId

		-- Correct Data
		;MERGE dbo.CS_SumCancelled AS TARGET
		USING #tmpSumCancelled AS SOURCE
			ON		TARGET.WinlostDate	= @WinlostDate
				AND TARGET.custid		= SOURCE.custid
				AND TARGET.ProductId	= SOURCE.ProductId
				AND TARGET.Sporttype	= SOURCE.Sporttype
				AND TARGET.Bettype		= SOURCE.Bettype
				AND TARGET.IsLive		= SOURCE.IsLive
				AND TARGET.CancelType	= SOURCE.CancelType
		WHEN MATCHED THEN UPDATE
			SET TARGET.Wagers			= SOURCE.Wagers,
				TARGET.Stake			= SOURCE.Stake,
				TARGET.HouseTurnover	= SOURCE.HouseTurnover,
				TARGET.HeadlineId		= SOURCE.HeadlineId
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(
				WinlostDate
				,CustId
				,ProductID
				,Sporttype
				,Bettype
				,IsLive
				,CancelType
				,Wagers
				,Stake
				,HouseTurnover
				,HeadlineId
			)
			VALUES
			(
				@WinlostDate
				,SOURCE.CustId
				,SOURCE.ProductID
				,SOURCE.Sporttype
				,SOURCE.Bettype
				,SOURCE.IsLive
				,SOURCE.CancelType
				,SOURCE.Wagers
				,SOURCE.Stake
				,SOURCE.HouseTurnover
				,SOURCE.HeadlineId
			)
		WHEN NOT MATCHED BY SOURCE
			AND TARGET.WinlostDate = @Winlostdate
			AND EXISTS (SELECT 1 FROM #CustInfo c WHERE TARGET.CustId = c.CustId)
			THEN DELETE;
	END
	/* ===== End Check and Correct Data ===== */

	DROP TABLE #tmpSumCancelled
	DROP TABLE #CustInfo
END
GO