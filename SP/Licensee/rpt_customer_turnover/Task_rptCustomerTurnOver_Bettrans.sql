/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerTurnOver_Bettrans] 
	@Date SMALLDATETIME
AS
/*   
	 Created: 20150910@Sophia  
	 DB: DBLIC.bodb_LicenseeReport  
	 Task: Gen data from bettrans before Move bets
	 Original: Task_rptCustomerTurnOver_Bettrans14
	 Revisions:   
		  - 20151223@Jim: Add "Effective Betting Value" in Customer Turnover report [Redmine: #45736]
		  - 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		  - 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		  - 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
*/ 
BEGIN 
SET NOCOUNT ON;

IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.rptCustomerTurnover AS rct WITH (NOLOCK)
		WHERE rct.winlostdate = @date
		)
BEGIN
	DELETE dbo.rptCustomerTurnover
	WHERE winlostdate = @Date
END;

WITH cte_parlayinfo
AS (
		SELECT DISTINCT b.transid, s.sporttype
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			CROSS APPLY (	SELECT TOP 1 m.sporttype
							FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
								INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
							WHERE b.refno = bm.refno AND b.custid = bm.custid
						) AS s
		WHERE b.bettype = 2799
			AND b.winlostdate = @date
			AND b.statusID IN (111, 112, 113)
			AND b.matchid = 2799		
)	
	,cte_bettrans
AS (
	SELECT a.CustID
		,a.currency
		,a.recommend
		,a.matchid
		,a.bettype
		,p.sporttype
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
	FROM bodb02.dbo.bettrans a WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) LC
		ON a.recommend = lc.custid AND a.currency = lc.currency
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction AS BA
		ON a.transid = ba.transid
		LEFT JOIN cte_parlayinfo p ON a.transid = p.transid
	WHERE a.winlostdate = @date
		AND a.statusID IN (111, 112, 113)
		AND a.bettype < 19999
		AND a.matchid >= 0 
	GROUP BY a.matchid
		,a.CustID
		,a.currency
		,a.recommend
		,a.bettype
		,p.sporttype
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
	FROM bodb02.dbo.VSOutright o WITH (NOLOCK)
		INNER JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK)
		ON r.EventID = o.EventID
	WHERE EventDate = @Date
	)

INSERT INTO dbo.rptCustomerTurnover
SELECT a.CustID
	,a.bettype
	,CASE 
		WHEN a.bettype IN (71, 72) THEN 251 --casino  
		WHEN a.bettype = 1000 THEN 253 --games  
		WHEN a.bettype BETWEEN 81
				AND 120 THEN 161 --Number Game   
		WHEN a.bettype BETWEEN 1101
				AND 1199 THEN 162 -- Live casino  
		WHEN a.bettype BETWEEN 1201 AND 1299 THEN CASE 
				WHEN result.sporttype IS NOT NULL THEN result.sporttype
				WHEN b.sporttype IS NOT NULL THEN b.sporttype
				ELSE 180 --Virtual Sport  
				END --Virtual Sport  
		WHEN a.bettype BETWEEN 51 AND 69 THEN 201
		WHEN a.bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno  
		WHEN a.bettype IN (31, 32, 33, 41, 42, 43) THEN 151
		WHEN a.bettype BETWEEN 2701 AND 2799 THEN CASE 
				WHEN a.bettype = 2799 THEN a.sporttype
				WHEN result.sporttype IS NOT NULL THEN result.sporttype
				WHEN b.sporttype IS NOT NULL THEN b.sporttype
				ELSE 190 -- Betradar VS
				END -- Betradar VS
		WHEN a.bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
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
		WHEN a.bettype = 2799 THEN -2799
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
	LEFT JOIN bodb02.dbo.match b WITH (NOLOCK)
	ON a.matchid = b.matchid
	LEFT JOIN cte_raceinfo result
	ON a.oddsid = result.Orid
	LEFT JOIN bodb02.dbo.outright AS ob WITH (NOLOCK)
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
		WHEN a.bettype BETWEEN 2701 AND 2799 THEN CASE 
				WHEN a.bettype = 2799 THEN a.sporttype
				WHEN result.sporttype IS NOT NULL THEN result.sporttype
				WHEN b.sporttype IS NOT NULL THEN b.sporttype
				ELSE 190 -- Betradar VS
				END -- Betradar VS
		WHEN a.bettype BETWEEN 1021 AND 1049 THEN 220 -- Lottery
		ELSE isNULL(b.sporttype, 0)
		END
	,a.Currency
	,a.Odds
	,oddstype
	,a.statusID
	,a.recommend
	,CASE 
		WHEN a.bettype IN (9, 29) THEN - 9
		WHEN a.bettype = 2799 THEN -2799
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