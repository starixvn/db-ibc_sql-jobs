SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


/****** Object:  Stored Procedure dbo.Task_rptCustomerTurnOver_Bettrans    Script Date: 1/14/2016 10:09:56 AM ******/

 
CREATE PROCEDURE [dbo].[Task_rptCustomerTurnOver_Bettrans] 
	@Date SMALLDATETIME
AS
/*   
	 Created: 20150910@Sophia  
	 DB: DBEXT/bodb02  
	 Task: Gen data from bettrans before Move bets
	 Original: Task_rptCustomerTurnOver_Bettrans14
	 Revisions:   
		  - 20151223@Jim: Add "Effective Betting Value" in Customer Turnover report [Redmine: #45736]
*/ 
BEGIN 
SET NOCOUNT ON;

IF EXISTS (
		SELECT TOP 1 1
		FROM bodb_LicenseeReport.dbo.rptCustomerTurnover AS rct WITH (NOLOCK)
		WHERE rct.winlostdate = @date
		)
BEGIN
	DELETE bodb_LicenseeReport.dbo.rptCustomerTurnover
	WHERE winlostdate = @Date
END;

WITH cte_bettrans
AS (
	SELECT a.CustID
		,a.currency
		,a.recommend
		,a.matchid
		,a.bettype
		,SUM(ABS(a.stake)) AS stake
		,sum(a.winlost - a.actual_stake) winlost
		,SUM(ABS(winlost - actual_stake)) AS BetEffective
		,sum(a.PlayerComm) PlayerComm
		,a.Odds
		,a.oddsid
		,a.oddstype
		,CASE 
			WHEN a.statusID = 112
				AND a.bettype IN (33, 43)
				AND a.liveawayscore = 0 THEN 114
			WHEN a.statusID = 113
				AND a.bettype IN (33, 43)
				AND a.liveawayscore = 0 THEN 115
			WHEN a.statusID = 112
				AND a.bettype IN (1, 3, 7, 8, 17, 18)
				AND ABS(modds) = 0.25 THEN 114
			WHEN a.statusID = 113
				AND a.bettype IN (1, 3, 7, 8, 17, 18)
				AND ABS(modds) = 0.25 THEN 115
			ELSE a.statusID
			END AS statusID
		,a.winlostdate
		,COUNT(a.custid) betcount
		,CASE 
			WHEN BA.transid IS NULL THEN 0
			WHEN BA.transid IS NOT NULL THEN 1
			END AS isBA
	--,sum(awinlost) awinlost  
	--,sum(comm) comm  
	FROM dbo.bettrans a WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) LC
		ON a.recommend = lc.custid
			AND a.currency = lc.currency
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction AS BA
		ON a.transid = ba.transid
	WHERE a.winlostdate = @date
		AND a.statusID IN (111, 112, 113)
		AND a.bettype < 19999
		AND a.matchid >= 0 
	GROUP BY a.matchid
		,a.CustID
		,a.currency
		,a.recommend
		,a.bettype
		,a.Odds
		,a.oddsid
		,a.oddstype
		,CASE 
			WHEN a.statusID = 112
				AND a.bettype IN (33, 43)
				AND a.liveawayscore = 0 THEN 114
			WHEN a.statusID = 113
				AND a.bettype IN (33, 43)
				AND a.liveawayscore = 0 THEN 115
			WHEN a.statusID = 112
				AND a.bettype IN (1, 3, 7, 8, 17, 18)
				AND ABS(modds) = 0.25 THEN 114
			WHEN a.statusID = 113
				AND a.bettype IN (1, 3, 7, 8, 17, 18)
				AND ABS(modds) = 0.25 THEN 115
			ELSE a.statusID
			END
		,a.winlostdate
		,CASE 
			WHEN BA.transid IS NULL THEN 0
			WHEN BA.transid IS NOT NULL THEN 1
			END
	)
	,cte_raceinfo
AS (
	SELECT o.Orid
		,r.SportType
		,r.LeagueID
	FROM dbo.VSOutright o WITH (NOLOCK)
		INNER JOIN dbo.VSRaceInfo r WITH (NOLOCK)
		ON r.EventID = o.EventID
	WHERE EventDate = @Date
	)


INSERT INTO bodb_LicenseeReport.dbo.rptCustomerTurnover
SELECT a.CustID
	,a.bettype
	,CASE 
		WHEN a.bettype IN (71, 72) THEN 251 --casino  
		WHEN a.bettype = 1000 THEN 253 --games  
		WHEN a.bettype BETWEEN 81
				AND 120 THEN 161 --Number Game   
		WHEN a.bettype BETWEEN 1101
				AND 1199 THEN 162 -- Live casino  
		WHEN a.bettype BETWEEN 1201
				AND 1299 THEN CASE 
				WHEN result.sporttype IS NOT NULL THEN result.sporttype
				WHEN b.sporttype IS NOT NULL THEN b.sporttype
				ELSE 180 --Virtual Sport  
				END --Virtual Sport  
		WHEN a.bettype BETWEEN 51
				AND 69 THEN 201
		WHEN a.bettype BETWEEN 1501
				AND 1599 THEN 202 -- Keno  
		WHEN a.bettype IN (31, 32, 33, 41, 42, 43) THEN 151
		ELSE isNULL(b.sporttype, 0)
		END sporttype
	,a.Currency
	,sum(stake) stake
	,sum(winlost) winlost
	,sum(playercomm) playercomm
	,a.Odds
	,oddstype
	,a.statusID
	,a.recommend
	,CASE 
		WHEN a.bettype IN (9, 29) THEN - 9
		WHEN a.bettype = 10
			OR (
				a.bettype > 30
				AND a.bettype < 50
				) THEN ISNULL(ob.leagueid, - 1)
		WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN isnull(result.LeagueID, - 1)
		ELSE isnull(b.LeagueID, - 1)
		END LeagueID
	,winlostdate
	,sum(a.betcount) betcount
	,a.isba
	,sum(BetEffective) BetEffective
--,sum(awinlost) awinlost  
--,sum(comm) comm  
FROM cte_bettrans a
	LEFT JOIN dbo.match b WITH (NOLOCK)
	ON a.matchid = b.matchid
	LEFT JOIN cte_raceinfo result
	ON a.oddsid = result.Orid
	LEFT JOIN dbo.outright AS ob WITH (NOLOCK)
	ON a.matchid = ob.orid
GROUP BY a.CustID
	,a.bettype
	,CASE 
		WHEN a.bettype IN (71, 72) THEN 251 --casino  
		WHEN a.bettype = 1000 THEN 253 --games  
		WHEN a.bettype BETWEEN 81
				AND 120 THEN 161 --Number Game   
		WHEN a.bettype BETWEEN 1101
				AND 1199 THEN 162 -- Live casino  
		WHEN a.bettype BETWEEN 1201
				AND 1299 THEN CASE 
				WHEN result.sporttype IS NOT NULL THEN result.sporttype
				WHEN b.sporttype IS NOT NULL THEN b.sporttype
				ELSE 180 --Virtual Sport  
				END --Virtual Sport  
		WHEN a.bettype BETWEEN 51
				AND 69 THEN 201
		WHEN a.bettype BETWEEN 1501
				AND 1599 THEN 202 -- Keno  
		WHEN a.bettype IN (31, 32, 33, 41, 42, 43) THEN 151
		ELSE isNULL(b.sporttype, 0)
		END
	,a.Currency
	,a.Odds
	,oddstype
	,a.statusID
	,a.recommend
	,CASE 
		WHEN a.bettype IN (9, 29) THEN - 9
		WHEN a.bettype = 10
			OR (
				a.bettype > 30
				AND a.bettype < 50
				) THEN ISNULL(ob.leagueid, - 1)
		WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN isnull(result.LeagueID, - 1)
		ELSE isnull(b.LeagueID, - 1)
		END
	,winlostdate
	,a.isba
 
 END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
