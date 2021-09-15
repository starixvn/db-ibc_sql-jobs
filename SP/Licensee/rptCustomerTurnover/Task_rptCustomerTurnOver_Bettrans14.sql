/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerTurnOver_Bettrans14] 
	@Date SMALLDATETIME
AS

/*	
	Created: 20131125@Florent Nguyen
	Task: Customer Performance Report
	DB: DBLIC.bodb_LicenseeReport
	
	Revision:
		- 20140305@Florent: Change way to get BA tickets
		- 20140315@Florent: Offer Keno sport
		- 20141130@Jim: change the way to retrieve currency value
		- 20150714@Francis: Adjustment to serve to change KeenOcean's currency RMB to HK$
		- 20151223@Jim: Add "Effective Betting Value" in Customer Turnover report [Redmine: #45736]
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
		- 20180212@Harper: Remove LC from product list [Redmine: #85965]
		- 20180409@Joseph: Implement new sports for VS2: BasketBall - Virual Soccer World Cup [Redmine: #90881]
		- 20180814@Joseph: Remove Racing [RedmineID: #99378]
		- 20181204@Bruce: Implement Happy 5 [RedmineID: #105723]
		- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_bk [RedmineID: #103656]
		- 20191220@Amanda: Integrate Spadegaming [RedmineID: #124103]
		- 20200622@Sol: Archive VSRaceInfo - changed to use VSRaceInfo14 [RedmineID: #135963]
		- 20200715@Kos: Extend Lottery bettype range [RedmineID: #137625] 
		- 20201231@Louis: Integrate Happy 5 Linked Games [RedmineID: #147446]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT TOP(1) 1 FROM dbo.rptCustomerTurnover WITH (NOLOCK) WHERE winlostdate = @Date)
	BEGIN
		DELETE dbo.rptCustomerTurnover WITH (ROWLOCK)
		WHERE winlostdate = @Date
	END

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date

	;WITH cte_parlayinfo
	AS (
		SELECT DISTINCT b.transid, s.sporttype
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			CROSS APPLY (	SELECT TOP 1 m.sporttype
							FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
								INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
							WHERE b.refno = bm.refno AND b.custid = bm.custid
						) AS s
		WHERE b.bettype = 2799
			AND b.winlostdate = @Date
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
			,SUM(a.winlost - a.actual_stake) winlost
			,SUM(ABS(winlost - actual_stake)) AS BetEffective
			,SUM(a.PlayerComm) PlayerComm
			,a.Odds
			,a.oddsid
			,a.oddstype
			,CASE
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.modds IN (-0.25, 0.25)
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9699)		-- Sportsbook
					AND a.bettype NOT IN (29,38,911,912,913,914 )	-- Parlay, betbuilder, Cashout
					AND a.bettype NOT BETWEEN 81 AND 120
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				WHEN a.winlostdate < @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
					AND ABS(modds) = 0.25
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				ELSE a.statusID
			END AS statusID
			,a.winlostdate
			,COUNT(a.custid) betcount
			,CASE 
				WHEN BA.transid IS NULL
					THEN 0
				WHEN BA.transid IS NOT NULL
					THEN 1
				END AS isBA
			--,SUM(awinlost) awinlost
			--,SUM(comm) comm
		FROM bodb02.dbo.bettrans14 a WITH (NOLOCK)
			INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) LC ON a.recommend = lc.custid AND a.currency = lc.currency
			LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_bk AS BA ON a.transid = ba.transid
			LEFT JOIN cte_parlayinfo p ON a.transid = p.transid
		WHERE a.winlostdate = @Date AND a.statusID IN (111, 112, 113)
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
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112,113)
					AND a.modds IN (-0.25, 0.25)
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9699)		-- Sportsbook
					AND a.bettype NOT IN (29,38,911,912,913,914 )	-- Parlay, betbuilder, Cashout
					AND a.bettype NOT BETWEEN 81 AND 120
				THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				WHEN a.winlostdate < @HWHLCutDate AND a.statusID IN (112,113)
					AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
					AND ABS(a.modds) = 0.25
				THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				ELSE a.statusID
				END
			,a.winlostdate
			,CASE 
				WHEN BA.transid IS NULL
					THEN 0
				WHEN BA.transid IS NOT NULL
					THEN 1
				END
		)
		,cte_raceinfo
	AS (
		SELECT o.Orid
			,r.SportType
			,r.LeagueID
		FROM bodb02.dbo.VSOutright14 AS o WITH (NOLOCK)
			INNER JOIN bodb02.dbo.VSRaceInfo14 AS r WITH (NOLOCK) ON r.EventID = o.EventID
		WHERE o.EventDate = @Date
		)
	INSERT INTO dbo.rptCustomerTurnover
	SELECT a.CustID
		,a.bettype
		,CASE 
			WHEN a.bettype IN (71, 72) THEN 251 --casino
			WHEN a.bettype = 1000 THEN 253 --games
			WHEN a.bettype BETWEEN 81 AND 120 THEN 161 --Number Game
			WHEN a.bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game: HP5
			WHEN a.bettype BETWEEN 3601 AND 3610 THEN 168 --Happy 5 Linked Games
			WHEN a.bettype BETWEEN 1201 AND 1299 THEN CASE 
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 180 --Virtual Sport
				END --Virtual Sport
			WHEN a.bettype BETWEEN 51 AND 69 THEN 201
			WHEN a.bettype BETWEEN 1501 AND 1599 THEN 202-- Keno
			WHEN a.bettype BETWEEN 2701 AND 2799 THEN CASE 
					WHEN a.bettype = 2799 THEN a.sporttype
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 190 -- Betradar VS
				END -- Betradar VS
			WHEN a.bettype BETWEEN 2800 AND 2829 THEN CASE 
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 193 -- Betradar VS: Virtual Basketball
				END -- Betradar VS: Virtual Basketball
			WHEN a.bettype BETWEEN 1021 AND 1099 THEN 220 -- Lottery
			WHEN a.bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			ELSE ISNULL(b.sporttype, 0)
			END sporttype
		,a.Currency
		,SUM(stake) stake
		,SUM(winlost) winlost
		,SUM(playercomm) playercomm
		,a.Odds
		,oddstype
		,a.statusID
		,a.recommend
		,CASE 
			WHEN a.bettype IN (9, 29) THEN - 9
			WHEN a.bettype = 2799 THEN -2799
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, - 1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238)
				THEN ISNULL(result.LeagueID, - 1)
			ELSE ISNULL(b.LeagueID, - 1)
			END LeagueID
		,winlostdate
		,SUM(a.betcount) betcount
		,a.isba
		,SUM(a.BetEffective) BetEffective
		--,SUM(awinlost) awinlost
		--,SUM(comm) comm
	FROM cte_bettrans a
		LEFT JOIN bodb02.dbo.match14 b WITH (NOLOCK) ON a.matchid = b.matchid
		LEFT JOIN cte_raceinfo result ON a.oddsid = result.Orid
		LEFT JOIN bodb02.dbo.outright14 AS ob WITH (NOLOCK) ON a.matchid = ob.orid
	GROUP BY a.CustID
		,a.bettype
		,CASE 
			WHEN a.bettype IN (71, 72) THEN 251 --casino
			WHEN a.bettype = 1000 THEN 253 --games
			WHEN a.bettype BETWEEN 81 AND 120 THEN 161 --Number Game
			WHEN a.bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game: HP5
			WHEN a.bettype BETWEEN 3601 AND 3610 THEN 168 --Happy 5 Linked Games
			WHEN a.bettype BETWEEN 1201 AND 1299 THEN CASE 
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 180 --Virtual Sport
				END --Virtual Sport
			WHEN a.bettype BETWEEN 51 AND 69 THEN 201
			WHEN a.bettype BETWEEN 1501 AND 1599 THEN 202-- Keno
			WHEN a.bettype BETWEEN 2701 AND 2799 THEN CASE 
					WHEN a.bettype = 2799 THEN a.sporttype
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 190 -- Betradar VS
				END -- Betradar VS
			WHEN a.bettype BETWEEN 2800 AND 2829 THEN CASE 
					WHEN result.sporttype IS NOT NULL THEN result.sporttype
					WHEN b.sporttype IS NOT NULL THEN b.sporttype
					ELSE 193 -- Betradar VS: Virtual Basketball
				END -- Betradar VS: Virtual Basketball
			WHEN a.bettype BETWEEN 1021 AND 1099 THEN 220 -- Lottery
			WHEN a.bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
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
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, - 1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238)
				THEN ISNULL(result.LeagueID, - 1)
			ELSE ISNULL(b.LeagueID, - 1)
			END
		,winlostdate
		,a.isba
END
GO
