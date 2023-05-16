/*<info serverAlias="DBARC-bodb_Report"></info>*/
/*
	Created: 20230504@Bobby
	Task: 172604 - LAP - Winloss Analysis - Gen historical data - UAT testing
	DB: DBARC.bodb_Report
	Remark: 
		- Step 1: Gen data in range bk DBARC - (DB061 or DB062)
		- Step 2: Import data on table rptLicenseeWinloss_UAT from DBARC.bodb_LicenseeReport to DB053.bodb_LicenseeReport.rptLicenseeWinloss
*/
use [bodb_Report]
go
  
DECLARE @FromDate	SMALLDATETIME = '2023-01-01',
	@ToDate			SMALLDATETIME = '2023-03-24',
	@winlostdate	SMALLDATETIME
;

BEGIN

	DECLARE @NASportType SMALLINT = 0, @TraceMsg VARCHAR(1000);
	DROP TABLE IF EXISTS #tmpAgency;
	DROP TABLE IF EXISTS #tmpBettype;

	CREATE TABLE #tmpAgency(recommend INT PRIMARY KEY, Currency INT);
	CREATE TABLE #tmpBettype (
		ProductID SMALLINT, 
		Product3rdID SMALLINT,
		BetType INT, 
		RefTable TINYINT,
		EventType TINYINT,
		CONSTRAINT PK_Bettype PRIMARY KEY (BetType, ProductID)
	);
	
	WITH CTE_Product AS (
		SELECT 0 AS ProductID, p.ProductName, p.ProductPrefix AS ProductCode
		FROM bodb02.dbo.Products p WITH(NOLOCK) 
		WHERE p.ProductID = 1
		UNION ALL
		SELECT DISTINCT p3.ProductID, p3.ProductName, p3.ProductPrefix AS ProductCode
		FROM bodb_licensee.dbo.Product3rd p3 WITH(NOLOCK)
		WHERE p3.Enabled = 1
	)
	INSERT INTO #tmpBettype
	SELECT tbl.ProductId, tbl.Product3rdId, tbl.Bettype, tbl.RefTable, tbl.EventType
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


	SET @winlostdate = @FromDate;
	----- Loop to Gen data
	WHILE (@winlostdate <= @ToDate)
	BEGIN
		DELETE #tmpAgency;

		INSERT INTO #tmpAgency
		SELECT b.recommend, cs.Currency
		FROM [bodb_Archive].[dbo].[bettrans_bk] b WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) on cs.custid = b.srecommend
		WHERE  b.winlostdate = @winlostdate
			AND b.statusID IN (111,112,113)
		GROUP BY b.recommend, cs.Currency;
			
	
		SET @TraceMsg = CONCAT('GEN >> bettrans_bk - ', FORMAT(@winlostdate, 'yyyyy-MM-dd'));
		RAISERROR (@TraceMsg, 0, 1) WITH NOWAIT;

		INSERT INTO bodb_Report.[dbo].[rptLicenseeWinloss_UAT]
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
			,COUNT(1) AS BetCount
			,SUM(ABS(ck.Turnover)) AS Turnover
			,SUM(ck.NetTurnover) AS NetTurnover
			,SUM(winlost-actual_stake) AS Winlost
			,SUM(b.awinlost) AS AWinlost
			,SUM(b.playercomm) AS [PComm]
			,SUM(b.comm) AS [AComm]
		FROM [bodb_Archive].[dbo].[bettrans_bk] b WITH(NOLOCK)
			INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
			INNER JOIN #tmpBettype s ON s.BetType = b.bettype AND s.RefTable NOT IN (1,2)
			LEFT JOIN [bodb_Archive].dbo.match_bk m WITH(NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN [bodb_Archive].[dbo].[Match3rd_bk] m3rd WITH(NOLOCK) ON m3rd.Match3rdId = b.matchid
			LEFT JOIN [bodb02].dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
			LEFT JOIN [bodb_Archive].dbo.outright_bk o WITH(NOLOCK) ON b.matchid = o.orid
			LEFT JOIN [bodb02].dbo.League lo WITH (NOLOCK) ON lo.leagueid = o.leagueid
			LEFT JOIN [bodb_Archive].dbo.VSRaceInfo_bk vs WITH(NOLOCK) ON b.matchid = vs.EventID
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

		SET @TraceMsg = CONCAT('GEN >> bettransRnG_bk - ', FORMAT(@winlostdate, 'yyyyy-MM-dd'));
		RAISERROR (@TraceMsg, 0, 1) WITH NOWAIT;

		INSERT INTO bodb_Report.[dbo].[rptLicenseeWinloss_UAT]
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
			,SUM(b.awinlost) AS AWinlost
			,SUM(b.playercomm) AS [PComm]
			,SUM(b.comm) AS [AComm]
		FROM [bodb_Archive].[dbo].[bettransRnG_bk] b WITH(NOLOCK)
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
	
	
		SET @TraceMsg = CONCAT('GEN >> bettransLC_bk - ', FORMAT(@winlostdate, 'yyyyy-MM-dd'));
		RAISERROR (@TraceMsg, 0, 1) WITH NOWAIT;

		INSERT INTO bodb_Report.[dbo].[rptLicenseeWinloss_UAT]
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
			,SUM(b.awinlost) AS AWinlost
			,SUM(b.playercomm) AS [PComm]
			,SUM(b.comm) AS [AComm]
		FROM [bodb_Archive].[dbo].[bettransLC_bk] b WITH(NOLOCK)
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
		
		SET @winlostdate = DATEADD(DAY, 1, @winlostdate);
		WAITFOR DELAY '00:00:00.250';
	END
END
GO
