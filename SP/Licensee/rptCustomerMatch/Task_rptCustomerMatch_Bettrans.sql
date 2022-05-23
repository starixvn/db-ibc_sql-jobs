/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerMatch_Bettrans]
	@Date SMALLDATETIME
AS

/*
	Created: 20150910@Sophia
	DB: DBLIC.bodb_LicenseeReport
	Task: Gen data from bettrans before Move bets

	Revisions:
		- 20160726@Francis: Move SP to bodb_LicenseeReport [Redmine: #60449]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20180814@Joseph: Remove Racing [RedmineID: #99378]
		- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_active [RedmineID: #103656]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210608@Kos: Add new column LiveIndicator [RedmineID: #156599]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20220211@Kos: Integrate Cricket phase 2 [RedmineID: #168034]
		- 20220513@Hogan: Integrate BitCoin [RedmineID: #160160]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT TOP(1) 1 FROM dbo.rptCustomerMatch WITH (NOLOCK) WHERE winlostdate = @Date )
	BEGIN
		DELETE dbo.rptCustomerMatch
		WHERE winlostdate = @Date
	END

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3, 5, 25, 27, 63, 69)

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date

	;WITH cte_bettrans AS (
		SELECT a.custid
			,a.recommend
			,a.matchid
			,a.oddsid
			,a.bettype
			,SUM(ABS(a.stake)) AS stake
			,SUM(a.winlost - a.actual_stake) AS winlost
			,a.odds
			,a.oddstype
			,CASE
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.modds IN (-0.25, 0.25)
					---- Sportsbook
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9998)
					AND a.bettype NOT IN (29, 38, 911, 912, 913, 914)	-- Parlay, betbuilder, Cashout
					AND a.bettype NOT BETWEEN 81 AND 120
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				WHEN a.winlostdate < @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
					AND ABS(a.modds) = 0.25
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				ELSE a.statusID
			END AS statusID
			,a.winlostdate
			,COUNT(a.custid) AS betcount
			,CASE 
				WHEN BA.transid IS NULL THEN 0
				WHEN BA.transid IS NOT NULL THEN 1
				END AS isBA
			,SUM(a.awinlost) AS awinlost
			,SUM(a.comm) AS comm
			,SUM(a.playercomm) AS playercomm
			,a.currency
			,a.liveindicator
		FROM bodb02.dbo.bettrans AS a WITH (NOLOCK)
			INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) AS LC ON a.recommend = lc.custid AND a.currency = lc.currency
			INNER JOIN @SportBettype AS s ON s.BetType = a.bettype
			LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON a.transid = ba.transid
		WHERE a.winlostdate = @Date
			AND a.statusID IN (111, 112, 113)
			AND a.bettype < 19999
			AND a.matchid >= 0
		GROUP BY a.custid
			,a.recommend
			,a.matchid
			,a.oddsid
			,a.bettype
			,a.odds
			,a.oddstype
			,CASE
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.modds IN (-0.25, 0.25)
					-- Sportsbook
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9998)
					AND a.bettype NOT IN (29, 38, 911, 912, 913, 914)	-- Parlay, betbuilder, Cashout
					AND a.bettype NOT BETWEEN 81 AND 120
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				WHEN a.winlostdate < @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
					AND ABS(a.modds) = 0.25
					THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
				ELSE a.statusID
			END
			,a.winlostdate
			,CASE 
				WHEN BA.transid IS NULL THEN 0
				WHEN BA.transid IS NOT NULL THEN 1
			END
			,a.currency
			,a.liveindicator
		)
		, cte_raceinfo AS (
			SELECT o.Orid
				,r.LeagueID
			FROM bodb02.dbo.VSOutright AS o WITH (NOLOCK)
				INNER JOIN bodb02.dbo.VSRaceInfo AS r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE o.EventDate = @Date
		)
	INSERT INTO dbo.rptCustomerMatch (
		custid
		,matchid
		,oddsid
		,LeagueID
		,bettype
		,Odds
		,oddstype
		,statusID
		,stake
		,winlost
		,winlostdate
		,awinlost
		,comm
		,playercomm
		,recommend
		,isba
		,betcount
		,currency
		,LiveIndicator
		)
	SELECT a.CustID
		,a.matchid
		,a.oddsid
		,CASE
			WHEN a.bettype IN (9, 29) THEN -9
			WHEN a.bettype = 2799 THEN -2799
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, -1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN ISNULL(r.LeagueID, -1)
			WHEN a.bettype BETWEEN 7901 AND 7999 THEN ISNULL(b3rd.league3rdId, -1)
			WHEN a.bettype BETWEEN 3611 AND 3620 THEN -63
			ELSE ISNULL(b.LeagueID, -1)
		END LeagueID
		,a.bettype
		,a.odds
		,a.oddstype
		,a.statusID
		,SUM(a.stake) AS stake
		,SUM(winlost) AS winlost
		,a.winlostdate
		,SUM(a.awinlost) AS awinlost
		,SUM(a.comm) AS Comm
		,SUM(a.playercomm) AS playercomm
		,a.recommend
		,a.isba
		,SUM(a.betcount) AS betcount
		,a.currency
		,a.liveindicator
	FROM cte_bettrans AS a
		LEFT JOIN bodb02.dbo.match AS b WITH (NOLOCK) ON a.matchid = b.matchid
		LEFT JOIN cte_raceinfo AS r ON a.oddsid = r.Orid
		LEFT JOIN bodb02.dbo.outright AS ob WITH (NOLOCK) ON a.matchid = ob.orid
		LEFT JOIN bodb02.dbo.match3rd AS b3rd WITH (NOLOCK) ON a.matchid = b3rd.match3rdId
	GROUP BY a.custid
		,a.matchid
		,a.oddsid
		,a.bettype
		,a.odds
		,a.oddstype
		,a.statusID
		,a.winlostdate
		,a.recommend
		,a.isba
		,CASE 
			WHEN a.bettype IN (9, 29) THEN -9
			WHEN a.bettype = 2799 THEN -2799
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, -1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN ISNULL(r.LeagueID, -1)
			WHEN a.bettype BETWEEN 7901 AND 7999 THEN ISNULL(b3rd.league3rdId, -1)
			WHEN a.bettype BETWEEN 3611 AND 3620 THEN -63
			ELSE ISNULL(b.LeagueID, -1)
		END
		,a.currency
		,a.liveindicator
END
GO
