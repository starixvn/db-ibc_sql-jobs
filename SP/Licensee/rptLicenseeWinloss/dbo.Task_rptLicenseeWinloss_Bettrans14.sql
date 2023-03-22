/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptLicenseeWinloss_Bettrans14]
	@winlostdate DATE,
	@IsCheckDataOnly BIT = 1
AS
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - GEN Bettrans
	DB: DBEXT.bodb02

	Revisions:
		- 20230209@Bobby: Created [RedmineID: #172604]
		
*/
BEGIN  
	SET NOCOUNT ON;

	DECLARE @NASportType SMALLINT = 0;
		
	DROP TABLE IF EXISTS #rptData;
	CREATE TABLE #tmpRptData (
		[Recommend] 		INT
	   ,[WinlostDate]		SMALLDATETIME
	   ,[Product3rdId]		INT
	   ,[Sporttype]			INT
	   ,[Bettype]			INT
	   ,[CustId]			INT
	   ,[StatusId]			TINYINT
	   ,[LiveIndicator]		TINYINT
	   ,[LeagueGroupId]		SMALLINT
	   ,[TicketType]		TINYINT
	   ,[Betfrom]			NVARCHAR(3)
	   ,[APositiontaking]	MONEY
	   ,[BetCount]			INT
	   ,[Turnover]			MONEY
	   ,[NetTurnover]		MONEY
	   ,[Winlost]			MONEY
	   ,[AWinlost]			MONEY
	   ,[PComm]				MONEY
	   ,[AComm]				MONEY
	);
	CREATE CLUSTERED INDEX CIX_tmpRptData ON #tmpRptData(
		[Recommend] 		
	   ,[WinlostDate]		
	   ,[Product3rdId]		
	   ,[Sporttype]			
	   ,[Bettype]
	);
	
	DROP TABLE IF EXISTS #tmpAgency 
	CREATE TABLE #tmpAgency(recommend INT PRIMARY KEY, Currency INT);
	
	INSERT INTO #tmpAgency
	SELECT b.recommend, cs.Currency
	FROM [bodb02].[dbo].[bettrans14] b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) on cs.custid = b.srecommend
	WHERE  b.winlostdate = @winlostdate
		AND b.statusID IN (111,112,113)
	GROUP BY b.recommend, cs.Currency;
		
	IF NOT EXISTS (
		SELECT TOP 1 1
		FROM bodb_LicenseeReport.[dbo].[rptLicenseeWinloss] rpt WITH(NOLOCK)
		INNER JOIN #tmpAgency a ON a.recommend = rpt.recommend
		WHERE rpt.winlostdate = @winlostdate
	)
	BEGIN
		PRINT 'DATA has NOT been ready on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');
		RETURN
	END
		
	DROP TABLE IF EXISTS #tmpBettype;

	WITH CTE_Product AS (
			SELECT 0 AS ProductID, p.ProductName, p.ProductPrefix AS ProductCode
			FROM bodb02.dbo.Products p WITH(NOLOCK) 
			WHERE p.ProductID = 1
			UNION ALL
			SELECT DISTINCT p3.ProductID, p3.ProductName, p3.ProductPrefix AS ProductCode
			FROM bodb_licensee.dbo.Product3rd p3 WITH(NOLOCK)
			WHERE p3.Enabled = 1
	)
	SELECT tbl.ProductId, tbl.Bettype, tbl.RefTable, tbl.EventType,tbl.Product3rdId
	INTO #tmpBettype
	FROM (
		SELECT DISTINCT p.ProductID, 
			p3.ProductID AS Product3rdID,
			m.BetType, 
			m.RefTable,
			m.EventType
		FROM CTE_Product p3 WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductPrefix = p3.ProductCode
		INNER JOIN bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK) ON m.ProductID = p.ProductID
	) AS tbl;
	
	
	PRINT 'GEN >> bettrans14';
	INSERT INTO #tmpRptData
	SELECT 
		b.Recommend,
		b.WinlostDate,
		CASE 
			WHEN s.ProductID = 1 AND ba.IsBA = 0 THEN 0
			WHEN s.ProductID = 1 AND ba.IsBA = 1 THEN 3 
			ELSE s.Product3rdID 
		END AS Product3rdId,
		ck.Sporttype,
		s.Bettype,
		b.CustId,
		b.StatusId,
		ck.LiveIndicator,
		ck.LeagueGroupId,
		ck.TicketType,
		b.Betfrom,
		b.APositiontaking
		----------------------
		,SUM(1) AS BetCount
		,SUM(ABS(ck.Turnover)) AS Turnover
		,SUM(ck.NetTurnover) AS NetTurnover
		,SUM(winlost-actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
	FROM [bodb02].[dbo].[bettrans14] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.bettype AND s.RefTable NOT IN (1,2)
		LEFT JOIN [bodb02].dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid
		LEFT JOIN [bodb02].[dbo].[Match3rd14] m3rd WITH(NOLOCK) ON m3rd.Match3rdId = b.matchid
		LEFT JOIN [bodb02].dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
		LEFT JOIN [bodb02].dbo.outright14 o WITH(NOLOCK) ON b.matchid = o.orid
		LEFT JOIN [bodb02].dbo.League lo WITH (NOLOCK) ON lo.leagueid = o.leagueid
		LEFT JOIN [bodb02].dbo.VSRaceInfo14 vs WITH(NOLOCK) ON b.matchid = vs.EventID
		LEFT JOIN [bodb_licensee].dbo.LicenseeBATransaction_bk AS lba WITH (NOLOCK) ON b.transid = lba.transid
		OUTER APPLY (
			SELECT 
				IIF(lba.TransID IS NOT NULL, 1, 0) AS IsBA
		) AS ba
		OUTER APPLY (
			SELECT 
				ABS(b.[stake]) AS Turnover,
				CASE
					WHEN s.RefTable IN (1,2) THEN 0 -- Gaming IN bettransRnG/bettransLC
					WHEN s.ProductID = 1 AND b.statusID IN (111) THEN 0
					WHEN s.ProductID = 1 AND b.statusID IN (112, 113) AND ABS(b.modds) = 0.25 THEN ABS(stake) / 2
					ELSE ABS(b.stake)
				END AS NetTurnover,
				CASE 
					WHEN s.EventType = 0 THEN
						CASE 
							WHEN b.matchid = 29 THEN -1		--Parlay Sport
							WHEN b.matchid = 2799 THEN ISNULL(b.oddsid, @NASportType)
							WHEN b.matchid = 999 THEN @NASportType	-- Odds Spread Adjustment
							WHEN b.matchid = 0 AND b.bettype = 1800 THEN 250	-- AG Casino 
							WHEN b.matchid = 0 AND b.bettype = 8000 THEN 221	-- Exchange
							ELSE ISNULL(b.matchid, @NASportType)
						END
					WHEN s.EventType = 1 THEN ISNULL(m.sporttype, @NASportType)
					WHEN s.EventType = 2 THEN ISNULL(lo.sporttype, @NASportType)
					WHEN s.EventType = 3 THEN ISNULL(vs.SportType, @NASportType)
					WHEN s.EventType = 5 THEN ISNULL(m3rd.Sporttype, @NASportType)
					ELSE @NASportType
				END AS SportType,
				CASE 
					WHEN ((l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
							OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
							OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
							OR (l.LeagueGroupID = 151 AND m.sporttype = 43)
						) AND b.betdaqid <> -2 
						THEN l.LeagueGroupID 
					ELSE 0
				END AS LeagueGroupID, -- Saba Sports
				CASE
					WHEN s.ProductId = 1 AND s.EventType = 1 AND b.betdaqid = -2 THEN 1 -- Castout
					ELSE 0
				END AS TicketType,
				CASE
					WHEN 
						b.statusID IN (112, 113)
						AND ABS(b.modds) =0.25
						AND (b.bettype < 999
							OR b.bettype BETWEEN 1301 AND 1399
							OR b.bettype BETWEEN 9001 AND 9399
							OR b.bettype BETWEEN 9400 AND 9998
							OR b.bettype BETWEEN 3900 AND 3999)	-- Sportsbook
						AND b.bettype NOT IN (29, 38, 911, 912, 913, 914)  --- Parlay, betbuilder, Cashout
						AND b.bettype NOT BETWEEN 81 AND 120
						THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
					WHEN 
						b.statusID IN (112, 113)
						AND b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
						AND ABS(b.modds) = 0.25
						THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
					ELSE b.statusID
				END AS statusID,
				ISNULL(CASE WHEN b.bettype IN(9,29) THEN b.livehomescore ELSE b.liveindicator END, 0) AS liveindicator
		) AS ck
		
	WHERE b.winlostdate = @winlostdate
		AND b.statusID IN (111,112,113)
	GROUP BY 
		b.Recommend,
		b.WinlostDate,
		CASE 
			WHEN s.ProductID = 1 AND ba.IsBA = 0 THEN 0
			WHEN s.ProductID = 1 AND ba.IsBA = 1 THEN 3 
			ELSE s.Product3rdID 
		END,
		ck.Sporttype,
		s.Bettype,
		b.CustId,
		b.StatusId,
		ck.LiveIndicator,
		ck.LeagueGroupId,
		ck.TicketType,
		b.Betfrom,
		b.APositiontaking

	PRINT 'GEN >> bettransRnG14';
	INSERT INTO #tmpRptData
	SELECT 
		b.Recommend,
		b.WinlostDate,
		s.Product3rdId,
		b.productID AS Sporttype,
		s.Bettype,
		b.CustId,
		b.StatusId,
		0 AS LiveIndicator,
		0 AS LeagueGroupId,
		0 AS TicketType,
		b.Betfrom,
		b.APositiontaking
		----------------------
		,COUNT(1) AS [BetCount]
		,SUM(ABS(b.stake)) AS Turnover
		,SUM(b.BetStake) AS NetTurnover
		,SUM(b.winlost-b.actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
	FROM [bodb02].[dbo].[bettransRnG14] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.gameID AND s.RefTable = 1
	WHERE b.winlostdate = @winlostdate
		AND b.statusID IN (111,112,113)
	GROUP BY
		b.Recommend,
		b.WinlostDate,
		s.Product3rdId,
		b.productID,
		s.Bettype,
		b.CustId,
		b.StatusId,
		b.Betfrom,
		b.APositiontaking
	
	
	PRINT 'GEN >> bettransLC14';
	INSERT INTO #tmpRptData
	SELECT 
		b.Recommend,
		b.WinlostDate,
		s.Product3rdId,
		b.productID AS Sporttype,
		s.Bettype,
		b.CustId,
		b.StatusId,
		0 AS LiveIndicator,
		0 AS LeagueGroupId,
		0 AS TicketType,
		b.Betfrom,
		b.APositiontaking
		----------------------
		,COUNT(1) AS [BetCount]
		,SUM(ABS(b.stake)) AS Turnover
		,SUM(b.NetStake) AS NetTurnover
		,SUM(b.winlost-b.actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
	FROM [bodb02].[dbo].[bettransLC14] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.gameID AND s.RefTable = 2

	WHERE b.winlostdate = @winlostdate
		AND b.statusID IN (111,112,113)
	GROUP BY
		b.Recommend,
		b.WinlostDate,
		s.Product3rdId,
		b.productID,
		s.Bettype,
		b.CustId,
		b.StatusId,
		b.Betfrom,
		b.APositiontaking;
		
	DECLARE @HasDiff BIT;
	
	--TODO: CHECK 
	DROP TABLE IF EXISTS #tmpDiffAgency;
	CREATE TABLE #tmpDiffAgency(recommend INT, CustId INT PRIMARY KEY, DiffFlag BIT /*1: Source, 0: Target*/);
	
	;WITH CTE_RptDataSource AS (
		SELECT b.[Recommend]
	           ,[CustId]
			   ,CHECKSUM_AGG(CHECKSUM([SportType],[APositiontaking],[BetCount],[Turnover],[NetTurnover],[Winlost],[AWinlost],[PComm],[AComm])) AS CheckSumData
		FROM [dbo].[rptLicenseeWinloss] b WITH(NOLOCK)
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		WHERE b.winlostdate = @winlostdate
		GROUP BY b.[Recommend]
	           ,[CustId]
	)
	INSERT INTO #tmpDiffAgency (Recommend, CustId, DiffFlag)
	SELECT DISTINCT ISNULL(b14.Recommend, s.Recommend) AS Recommend
		,ISNULL(b14.CustId, s.CustId) AS CustId
		,IIF(b14.CustId > 0, 1, 0) AS DiffFlag
	FROM (
		SELECT [Recommend]
	           ,[CustId]
			   ,CHECKSUM_AGG(CHECKSUM([SportType],[APositiontaking],[BetCount],[Turnover],[NetTurnover],[Winlost],[AWinlost],[PComm],[AComm])) AS CheckSumData
		FROM #tmpRptData
			GROUP BY 
				[Recommend]
	           ,[CustId]
	) AS b14
	FULL OUTER JOIN CTE_RptDataSource AS s ON
			s.[Recommend] = b14.Recommend AND s.[CustId]= b14.CustId
	WHERE s.[CustId]  	IS NULL
		OR b14.[CustId]  IS NULL
		OR s.CheckSumData 	<> 	b14.CheckSumData
	
	SET @HasDiff = IIF(@@ROWCOUNT > 0, 1, 0);

	IF @HasDiff = 0
	BEGIN
		PRINT 'LAP - WinlossAnalysis - bettrans14 - CheckAndCorrect: OK on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');
		RETURN;
	END
	ELSE
	BEGIN
		PRINT 'LAP - WinlossAnalysis - bettrans14 - CheckAndCorrect: Diff DATA found on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');
		IF @IsCheckDataOnly = 1
		BEGIN
			SELECT * FROM #tmpDiffAgency;
		END
	END
		
	IF @HasDiff = 1 AND @IsCheckDataOnly = 0
	BEGIN
		PRINT 'CheckAndCorrect on bettrans14 has been running on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');

		-- TODO: DataCheckingLog
		-- Save CustID into BetTypeId for quick checking
		INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, BetTypeId, IsSource, ExtraInfo)
		SELECT @winlostdate AS WinlostDate, 
			OBJECT_NAME(@@PROCID)  AS SPName, 
			'rptLicenseeWinloss' AS TableName, 
			tmp.CustId,
			DiffFlag,
			CONCAT('{"bet":', ISNULL(bet.jsonVal, '[]'),',"bet14":',ISNULL(bet14.jsonVal,'[]'),'}') AS ExtraInfo
		FROM #tmpDiffAgency tmp
		OUTER APPLY (
			SELECT jsonVal = (
				SELECT [SportType],[APositiontaking],[BetCount],[Turnover],[NetTurnover],[Winlost],[AWinlost],[PComm],[AComm]
				FROM dbo.rptLicenseeWinloss rpt WITH(NOLOCK) WHERE rpt.CustId = tmp.CustId AND rpt.WinlostDate = @winlostdate
				FOR JSON PATH
			)
		) AS bet
		OUTER APPLY (
			SELECT jsonVal = (
				SELECT [SportType],[APositiontaking],[BetCount],[Turnover],[NetTurnover],[Winlost],[AWinlost],[PComm],[AComm]
				FROM #tmpRptData rpt WHERE rpt.CustId = tmp.CustId AND rpt.WinlostDate = @winlostdate
				FOR JSON PATH
			)
		) AS bet14
		
		-- TODO: DELETE the DIFF rows
		DELETE rpt
		FROM [dbo].[rptLicenseeWinloss] rpt
		INNER JOIN #tmpDiffAgency a ON a.Recommend = rpt.Recommend AND a.CustId = rpt.CustId
		WHERE rpt.WinlostDate = @winlostdate
		
		-- TODO: INSERT the NEW rows
		INSERT INTO bodb_LicenseeReport.[dbo].[rptLicenseeWinloss]
	           ([Recommend]
	           ,[WinlostDate]
	           ,[Product3rdId]
	           ,[Sporttype]
	           ,[Bettype]
	           ,[CustId]
	           ,[StatusId]
	           ,[LiveIndicator]
	           ,[LeagueGroupId]
	           ,[TicketType]
	           ,[Betfrom]
	           ,[APositiontaking]
	           ,[BetCount]
	           ,[Turnover]
	           ,[NetTurnover]
	           ,[Winlost]
	           ,[AWinlost]
	           ,[PComm]
	           ,[AComm]
			  )
		SELECT b.[Recommend]
	           ,[WinlostDate]
	           ,[Product3rdId]
	           ,[Sporttype]
	           ,[Bettype]
	           ,b.[CustId]
	           ,[StatusId]
	           ,[LiveIndicator]
	           ,[LeagueGroupId]
	           ,[TicketType]
	           ,[Betfrom]
	           ,[APositiontaking]
	           ,[BetCount]
	           ,[Turnover]
	           ,[NetTurnover]
	           ,[Winlost]
	           ,[AWinlost]
	           ,[PComm]
	           ,[AComm]
		FROM #tmpRptData b
		INNER JOIN #tmpDiffAgency a ON a.Recommend = b.Recommend AND a.CustId = rpt.CustId
		WHERE a.DiffFlag = 1;
	END
END
GO