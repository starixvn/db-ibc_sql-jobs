/*<info serverAlias="DBSUM-bodb_Summary" executers="" isFunction="0" isNested="1"></info>*/
USE bodb_Summary
GO

ALTER PROCEDURE [dbo].[Task_CS_SumCancelled]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20190809@Percy
	Task: Gen data for CS_SumCancelled
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20190809@Percy: Initialize SP [RedmineID: #116925]
*/

BEGIN
	SET NOCOUNT ON

	/* ===== Get data ===== */
	BEGIN
		-- bettrans
		CREATE TABLE #tmpBettrans
		(
			srecommend	INT
			,mrecommend	INT
			,recommend	INT
			,custid		INT
			,matchid	INT
			,ProductID	INT
			,bettype	INT
			,eventtype	TINYINT
			,IsLive		BIT
			,CancelType	TINYINT
			,Wagers		INT
			,Stake		MONEY
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
					,CASE WHEN b.ExtraInfo LIKE '%p1%' AND t.c = 1 THEN 2 ELSE 1 END AS CancelType
					,b.stake
				FROM bodb02.dbo.bettrans b WITH (NOLOCK)
					OUTER APPLY (
						SELECT TOP 1 bm.matchid
						FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						WHERE b.refno = bm.refno AND b.bettype = 2799
					) AS s
					OUTER APPLY (SELECT CAST(('<xml>' + ISNULL(b.ExtraInfo, '') + '</xml>') AS XML).value('data(/xml/p1/@ab)[1]','TINYINT')) AS t(c)
				WHERE c.CustId = b.srecommend
					AND b.statusID IN (101, 102, 103)
			) AS b
			CROSS APPLY (SELECT TOP 1 sbm.ProductID, sbm.eventtype FROM bodb02.dbo.CS_SportBettypeMatrix sbm WITH (NOLOCK) WHERE b.bettype = sbm.bettype) AS s
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
		CREATE TABLE #tmpSumCancelled
		(
			srecommend	INT
			,mrecommend	INT
			,recommend	INT
			,custid		INT
			,ProductId	SMALLINT
			,Sporttype	SMALLINT
			,Bettype	SMALLINT
			,IsLive		BIT
			,CancelType	TINYINT
			,Wagers		INT
			,Stake		MONEY
			,HeadlineId	INT
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
			,SUM(b.Wagers)	AS Wagers
			,SUM(b.Stake)	AS Stake
			,cs.UplineId
		FROM #tmpBettrans b
			CROSS APPLY (
				SELECT m.sporttype
				FROM bodb02.dbo.match m WITH (NOLOCK)
				WHERE b.matchid = m.matchid AND b.eventtype = 1 -- included Betradar VS Parlay

				UNION ALL
				SELECT l.sporttype
				FROM bodb02.dbo.outright o WITH (NOLOCK)
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
			,b.CancelType
			,cs.UplineId

		DROP TABLE #tmpBettrans
	END
	/* ===== End Get data ===== */

	/* ===== Check and Correct Data ===== */
	BEGIN
		DECLARE @Rowcount INT

		;WITH CTE_CS_SumCancelled AS (
			SELECT
				s.custid
				,s.ProductId
				,s.Sporttype
				,s.bettype
				,s.IsLive
				,s.CancelType
				,s.Wagers
				,s.Stake
				,s.HeadlineId
			FROM dbo.CS_SumCancelled s WITH (NOLOCK)
			WHERE s.WinlostDate	= @WinlostDate
				AND EXISTS (SELECT 1 FROM bodb02.dbo.custInfo c WITH (NOLOCK) WHERE s.custid = c.custid AND c.roleid = 1)
		)
		SELECT @Rowcount = COUNT(1)
		FROM CTE_CS_SumCancelled s
			FULL OUTER JOIN #tmpSumCancelled t
				ON		s.custid		= t.custid
					AND s.ProductId		= t.ProductId
					AND s.Sporttype		= t.Sporttype
					AND s.bettype		= t.bettype
					AND s.IsLive		= t.IsLive
					AND s.CancelType	= t.CancelType
		WHERE s.custid IS NULL
			OR t.custid IS NULL
			OR s.Wagers		<> t.Wagers
			OR s.Stake		<> t.Stake
			OR s.HeadlineId <> t.HeadlineId
		
		IF @Rowcount <> 0
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
				,HeadlineId
			)
			SELECT
				recommend AS custid
				,ProductId
				,Sporttype
				,Bettype
				,IsLive
				,CancelType
				,SUM(Wagers) AS Wagers
				,SUM(Stake) AS Stake
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
				,SUM(Wagers) AS Wagers
				,SUM(Stake) AS Stake
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
				,SUM(Wagers) AS Wagers
				,SUM(Stake) AS Stake
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
					,SOURCE.HeadlineId
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN DELETE;
		END
	END
	/* ===== End Check and Correct Data ===== */

	DROP TABLE #tmpSumCancelled
END
GO