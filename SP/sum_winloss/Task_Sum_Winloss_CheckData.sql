/*<info serverAlias="DBAGE-bodb02" isNested="1"></info>*/
CREATE PROCEDURE Task_Sum_Winloss_CheckData
	@WinlostDate SMALLDATETIME 
/*
	Created: 20231018@Lewis
	DB: DBAGE.bodb02
	Task: Cross check data [RedmineID: #193254]

	Revisions:
		- 20231018@Lewis: Initialize SP [RedmineID: #193254]
		- 20240219@Lewis: Add Live22 PromotionPrize - bettype = 7698 [RedmineID: #201011]	
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]

*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ProductIds VARCHAR(MAX)
	SELECT  @ProductIds = COALESCE(@ProductIds + ',', '') + CONVERT(VARCHAR(10), ProductId) FROM dbo.Products WITH (NOLOCK)
	-- Get @SabaInfo_CutOffDate
	DECLARE @SabaInfo_CutOffDate SMALLDATETIME

	SELECT @SabaInfo_CutOffDate = f.CutoffDate
	FROM dbo.f_GetCutOffDate() f
	WHERE f.TypeName = 'SabaSport'

	-- Get Custid not in Dep
	CREATE TABLE #CustId (CustId INT)
	INSERT INTO #CustId (CustId)
	SELECT custid 
	FROM Customer WITH (NOLOCK)
	WHERE srecommend NOT IN (SELECT custid FROM Dep_CustSuper WITH (NOLOCK))
		AND roleid = 4
	
	-- Get data bettype 
	CREATE TABLE #Bettypes (
		ProductId INT
		, SportTypeRef INT
		, BettypeRef INT
		, Bettype SMALLINT
		, RefTable TINYINT)
	INSERT INTO #Bettypes (
		ProductId
		, SportTypeRef
		, BettypeRef
		, Bettype
		, RefTable)
	SELECT f.ProductID
		, f.SportType AS SportTypeRef
		, f.BetType AS BettypeRef
		, s.BetType
		, s.RefTable
	FROM dbo.f_SumWinloss_ConditionSel(@ProductIds) f
		CROSS APPLY (
			SELECT DISTINCT s.RefTable, s.BetType FROM dbo.SportBettypeMatrix s WITH (NOLOCK)
			WHERE f.ProductID = s.ProductID
				AND (f.ProductID <> 6 OR f.SportType = s.SportType)
				AND (f.BetType NOT IN (3150, 4297, 4298, 4599, 4600, 8695, 2499, 7698) AND s.BetType NOT IN (3150, 4297, 4298, 4599, 4600, 8695, 2499, 7698) OR f.BetType = s.BetType)
		) AS s

	-- Get Data From bettrans14
	BEGIN
		CREATE TABLE #tmpBettrans
		(
			winlostdate			DATETIME
			,custid				INT
			,winlost			MONEY
			,playercomm			MONEY
			,BetCount			INT
			,sporttype			SMALLINT
			,bettype			SMALLINT
			,productid			INT
		)
		INSERT INTO #tmpBettrans
		(
			winlostdate
			,custid
			,winlost
			,playercomm
			,BetCount
			,sporttype
			,bettype
			,productid
		)
		SELECT
			b.winlostdate
			,b.custid
			,SUM(b.winlost - b.actual_stake) AS winlost
			,SUM(b.playercomm) AS playercomm
			,SUM(CASE	WHEN b.bettype = 500 THEN 0
						ELSE 1 END) AS BetCount
			,bt.sporttypeRef AS sporttype
			,bt.bettypeRef AS bettype
			,bt.ProductId
		FROM #CustId cus
		CROSS APPLY 
		(
				SELECT
					winlostdate
					,b.custid
					,b.actual_stake
					,b.winlost
					,b.playercomm
					,b.bettype
					,CASE WHEN ( 
								(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
								OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
								OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
								OR (l.LeagueGroupID = 42 AND m.sporttype = 5)
								OR (l.LeagueGroupID = 42 AND m.sporttype = 4) --Virtual Ice Hockey
								OR (l.LeagueGroupID = 42 AND m.sporttype = 47) --SABA Kabaddi
								OR (l.LeagueGroupID = 151 AND m.sporttype = 43)
							 ) AND betdaqid <> -2 AND winlostdate >= @SabaInfo_CutOffDate  THEN m.sporttype ELSE 0 END AS sporttype
				FROM dbo.bettrans14 b WITH (NOLOCK)
					LEFT JOIN dbo.match14 m WITH (NOLOCK) ON b.matchid = m.matchid
					LEFT JOIN (
								SELECT LeagueGroupID, leagueid
								FROM dbo.League l WITH(NOLOCK) WHERE l.LeagueGroupID IN (42,74,108,113,122,151)
							  )l  ON m.leagueid = l.leagueid
				WHERE b.winlostdate = @WinlostDate
					AND cus.custid = b.srecommend
					AND b.statusID IN (111,112,113)
			) AS b
			CROSS APPLY (
						SELECT DISTINCT c.ProductId,c.bettyperef,c.sporttyperef 
						FROM #Bettypes c 
						WHERE b.bettype = c.bettype
						AND	  (
								(b.sporttype = c.sporttyperef AND c.ProductId = 1) OR (c.ProductId <> 1)
							  )
						 
					) bt
		GROUP BY
			b.winlostdate
			,b.custid
			,bt.sporttypeRef
			,bt.bettypeRef
			,bt.ProductId

	END
	
	-- Get Data From sum_winloss
	BEGIN
		CREATE TABLE #tmpSum
		(
			winlostdate			DATETIME
			,custid				INT
			,winlost			MONEY
			,playercomm			MONEY
			,BetCount			INT
			,sporttype			SMALLINT
			,bettype			SMALLINT
			,productid			INT
		)
		INSERT INTO #tmpSum
		(
			winlostdate
			,custid
			,winlost
			,playercomm
			,BetCount
			,sporttype
			,bettype
			,productid
		)
		SELECT 
			a.winlostdate
			,a.custid
			,SUM(a.winlost) winlost
			,SUM(a.playercomm) playercomm
			,SUM(a.BetCount) BetCount
			,a.sporttype
			,a.bettype
			,c.ProductId 
		FROM sum_winloss a WITH (NOLOCK) 
		CROSS APPLY (
						SELECT DISTINCT b.ProductId,b.bettyperef,b.sporttyperef 
						FROM #Bettypes b 
						WHERE a.sporttype = b.sporttyperef
						AND a.bettype = b.bettyperef
					) c
		WHERE a.winlostdate = @WinlostDate 
			AND a.srecommend IN (SELECT custid FROM #CustId)
			AND a.roleid = 1
		GROUP BY 
			a.winlostdate
			,a.custid
			,a.sporttype
			,a.bettype
			,c.productid
	END

	-- compare
	DECLARE @result TABLE (
		custid INT
		, winlostdate SMALLDATETIME
		, productid INT
		, winlost_sum money
		, winlost_bettrans money
		, playercomm_sum money
		, playercomm_bettrans money)
	INSERT INTO @result (
		custid 
		, winlostdate 
		, productid 
		, winlost_sum 
		, winlost_bettrans 
		, playercomm_sum 
		, playercomm_bettrans )
	SELECT 
		COALESCE(a.custid,b.custid)
		, COALESCE(a.winlostdate,b.winlostdate)
		, COALESCE(a.productid,b.productid)
		, a.winlost
		,b.winlost
		,a.playercomm
		,b.playercomm
	FROM (
			SELECT winlostdate,custid,SUM(winlost) winlost, SUM(playercomm) playercomm, SUM(BetCount) BetCount,productid 
			FROM #tmpSum
			GROUP BY winlostdate,custid,productid 
		 ) a 
	FULL OUTER JOIN 
		 (
			SELECT winlostdate,custid,SUM(winlost) winlost, SUM(playercomm) playercomm, SUM(BetCount) BetCount,productid 
			FROM #tmpBettrans
			GROUP BY winlostdate,custid,productid
		 ) b
			ON a.custid = b.custid
			AND a.winlostdate = b.winlostdate
			AND a.productid = b.productid
		WHERE a.custid IS NULL OR b.custid IS NULL
			OR a.winlost <> b.winlost
			OR a.playercomm <> b.playercomm
			OR a.betcount <> b.betcount
			OR a.productid <> b.productid

	SELECT custid 
		, winlostdate 
		, productid 
		, winlost_sum 
		, winlost_bettrans 
		, playercomm_sum 
		, playercomm_bettrans
	FROM @result
	
	DROP TABLE #Bettypes
	DROP TABLE #tmpBettrans
	DROP TABLE #tmpSum
	DROP TABLE #CustId

END

