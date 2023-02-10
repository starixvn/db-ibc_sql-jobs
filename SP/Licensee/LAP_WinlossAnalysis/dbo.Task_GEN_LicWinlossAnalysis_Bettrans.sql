/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

CREATE OR ALTER PROCEDURE [dbo].[Task_GEN_LicWinlossAnalysis_Bettrans]
	@winlostdate DATE,
	@IsReGEN BIT = 1
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

	DECLARE @FromDate	SMALLDATETIME = @winlostdate,
		@ToDate			SMALLDATETIME = @winlostdate;
	
	DROP TABLE IF EXISTS #tmpAgency 
	
	CREATE TABLE #tmpAgency(recommend INT, Currency INT);
	
	INSERT INTO #tmpAgency
	SELECT b.recommend, cs.Currency
	FROM [bodb02].[dbo].[bettrans] b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) on cs.custid = b.srecommend
	WHERE  b.winlostdate BETWEEN @FromDate AND @ToDate
		AND b.statusID IN (111,112,113)
	GROUP BY b.recommend, cs.Currency;
		
	IF EXISTS (
		SELECT TOP 1 1
		FROM bodb_LicenseeReport.[dbo].[rptLicenseeWinloss] rpt WITH(NOLOCK)
		INNER JOIN #tmpAgency a ON a.recommend = rpt.recommend
		WHERE rpt.winlostdate BETWEEN @FromDate AND @ToDate
	)
	BEGIN
		PRINT 'DATA has been ready on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');
		IF @IsReGEN = 0
			RETURN;

		------ Clean Old Data then Re-GEN 
		WHILE EXISTS (
			SELECT TOP 1 1 
			FROM bodb_LicenseeReport.[dbo].[rptLicenseeWinloss] rpt WITH(NOLOCK)
			INNER JOIN #tmpAgency a ON a.recommend = rpt.recommend
			WHERE rpt.winlostdate BETWEEN @FromDate AND @ToDate)
		BEGIN
			DELETE TOP(10000) rpt
			FROM bodb_LicenseeReport.[dbo].[rptLicenseeWinloss] rpt
			INNER JOIN #tmpAgency a ON a.recommend = rpt.recommend
			WHERE rpt.winlostdate BETWEEN @FromDate AND @ToDate;
		END

		PRINT 'GEN-DATA-bettrans has been running on that day ' + FORMAT(@winlostdate, 'yyyy-MM-dd');
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
	SELECT tbl.ProductId, tbl.Bettype, tbl.RefTable, tbl.EventType,
		CASE WHEN tbl.RefTable IN (1,2) OR tbl.ProductID = 47 THEN 1 ELSE 0 END IsUsingOddsSpread,
		CASE WHEN cont.Bettype IS NOT NULL THEN 1 ELSE 0 END AS IsContributionBettype,
		tbl.Product3rdId
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
	) AS tbl
	OUTER APPLY 
	(
		SELECT f.Bettype
		FROM bodb02.dbo.f_BettypePrizeGroup() f
		WHERE f.BettypeGroup = 'Contribution'
			AND f.Bettype = tbl.bettype
	) AS cont;
	
	
	SELECT 'bettrans';

	;WITH CTE_SabaSporttypeRef AS (
		SELECT t.SportType AS SabaSportType, t.SportType, t.LeagueGroupID
		FROM bodb02.[dbo].[LAP_f_WinlossAnalysis_SabaSportSel] () AS saba
		CROSS APPLY
		(
			SELECT Sporttype, LeagueGroupID
			FROM OPENJSON(saba.SporttypeRef)
			WITH (Sporttype INT '$.Sporttype',
				LeagueGroupIDs NVARCHAR(MAX) '$.LeagueGroupID' AS JSON
			)
			CROSS APPLY OPENJSON(LeagueGroupIDs) WITH (LeagueGroupID VARCHAR(20) '$')
		) AS t
		WHERE saba.SporttypeRef IS NOT NULL
	)
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
	           ,[IsBA]
	           ,[APositiontaking]
	           ,[BetCount]
	           ,[Turnover]
	           ,[NetTurnover]
	           ,[Winlost]
	           ,[AWinlost]
	           ,[PComm]
	           ,[AComm]
	           ,[BetEffective]
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
		ba.IsBA,
		b.APositiontaking
		----------------------
		,SUM(1) AS BetCount
		,SUM(ABS(ck.Turnover)) AS Turnover
		,SUM(ck.NetTurnover) AS NetTurnover
		,SUM(winlost-actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
		,SUM(IIF(ba.IsBA = 1, 0, ABS(b.winlost))) AS BetEffective
	FROM [bodb02].[dbo].[bettrans] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.bettype AND s.RefTable NOT IN (1,2)
		LEFT JOIN [bodb02].dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		LEFT JOIN [bodb02].dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
		LEFT JOIN [bodb02].dbo.outright o WITH(NOLOCK) ON b.matchid = o.orid
		LEFT JOIN [bodb02].dbo.League lo WITH (NOLOCK) ON lo.leagueid = o.leagueid
		LEFT JOIN [bodb02].dbo.VSRaceInfo vs WITH(NOLOCK) ON b.matchid = vs.EventID
		LEFT JOIN [bodb_licensee].dbo.LicenseeBATransaction AS lba WITH (NOLOCK) ON b.transid = lba.transid
		OUTER APPLY (
			SELECT 
				IIF(lba.TransID IS NOT NULL, 1, 0) AS IsBA
		) AS ba
		OUTER APPLY ( 
			SELECT TOP 1 SabaSportType 
			FROM CTE_SabaSporttypeRef ref 
			WHERE s.ProductId = 1 AND ref.Sporttype = m.Sporttype AND ref.LeagueGroupID = l.LeagueGroupID
		) AS saba
		OUTER APPLY (
			SELECT 
				ABS(b.[stake]) AS Turnover,
				CASE
					WHEN s.RefTable IN (1,2) THEN 0 -- Gaming IN bettransRnG/bettransLC
					WHEN s.ProductID = 1 AND b.statusID IN (111) THEN 0
					WHEN s.ProductID = 1 AND b.statusID IN (112, 113) AND ABS(b.modds) = 0.25 THEN ABS(stake) / 2
					WHEN s.IsUsingOddsSpread = 1 THEN b.oddsspread -- BBIN
					ELSE ABS(b.stake)
				END AS NetTurnover,
				-(CASE
					WHEN ba.IsBA = 1 THEN (b.winlost + b.awinlost + b.comm) --COUNT for BA's tickets
					ELSE 0
				END) AS AmtDueToBA,
				CASE 
					WHEN s.EventType = 1 THEN 
						CASE 
							WHEN s.ProductId = 1 AND s.EventType = 1 AND b.betdaqid = -2 THEN -2 --> Castout Sport 
							ELSE CAST(ISNULL(saba.SabaSportType, ISNULL(m.sporttype,-9999)) AS INT)
						END
					WHEN s.EventType = 2 THEN CAST(lo.sporttype AS INT)
					WHEN s.EventType = 3 THEN CAST(vs.SportType AS INT)
					WHEN s.EventType = 0 THEN
						CASE WHEN b.matchid = 29 THEN -1 --Parlay Sport
						ELSE b.matchid
						END
					ELSE 0
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
						--b.winlostdate < HWHLCutDate AND 
						b.statusID IN (112, 113)
						AND b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
						AND ABS(b.modds) = 0.25
						THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
					ELSE b.statusID
				END AS statusID,
				ISNULL(CASE WHEN b.bettype IN(9,29) THEN b.livehomescore ELSE b.liveindicator END, 0) AS liveindicator
		) AS ck
		
	WHERE b.winlostdate BETWEEN @FromDate AND @ToDate
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
		ba.IsBA,
		b.APositiontaking
	ORDER BY b.winlostdate


	SELECT 'bettransRnG';

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
	           ,[IsBA]
	           ,[APositiontaking]
	           ,[BetCount]
	           ,[Turnover]
	           ,[NetTurnover]
	           ,[Winlost]
	           ,[AWinlost]
	           ,[PComm]
	           ,[AComm]
	           ,[BetEffective]
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
		0 AS IsBA,
		b.APositiontaking
		----------------------
		,COUNT(1) AS [BetCount]
		,SUM(ABS(b.stake)) AS Turnover
		,SUM(b.BetStake) AS NetTurnover
		,SUM(b.winlost-b.actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
		,SUM(ABS(b.winlost-b.actual_stake)) AS BetEffective
	FROM [bodb02].[dbo].[bettransRnG] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.gameID AND s.RefTable IN (1,2)
	WHERE b.winlostdate BETWEEN @FromDate AND @ToDate
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
	
	
	SELECT 'bettransLC';
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
	           ,[IsBA]
	           ,[APositiontaking]
	           ,[BetCount]
	           ,[Turnover]
	           ,[NetTurnover]
	           ,[Winlost]
	           ,[AWinlost]
	           ,[PComm]
	           ,[AComm]
	           ,[BetEffective]
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
		0 AS IsBA,
		b.APositiontaking
		----------------------
		,COUNT(1) AS [BetCount]
		,SUM(ABS(b.stake)) AS Turnover
		,SUM(b.NetStake) AS NetTurnover
		,SUM(b.winlost-b.actual_stake) AS Winlost
		,SUM(b.playercomm) AS [PComm]
		,SUM(b.awinlost) AS AWinlost
		,SUM(b.comm) AS [AComm]
		,SUM(ABS(b.winlost-b.actual_stake)) AS BetEffective
	FROM [bodb02].[dbo].[bettransLC] b WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.Dep_CustSuper pl WITH(NOLOCK) on pl.custid = b.srecommend
		INNER JOIN #tmpAgency pl WITH(NOLOCK) on pl.recommend = b.recommend
		INNER JOIN #tmpBettype s ON s.BetType = b.gameID AND s.RefTable IN (1,2)

	WHERE b.winlostdate BETWEEN @FromDate AND @ToDate
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
END
GO
exec [dbo].[Task_GEN_LicWinlossAnalysis_Bettrans] '2023-02-01';
GO

SELECT * FROM bodb_LicenseeReport.[dbo].[rptLicenseeWinloss] rpt WITH(NOLOCK) where WinlostDate='2023-02-01'