/*<info serverAlias="DBLIC-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptWinlostbyleague_Bettrans]
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
*/

BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT TOP(1) 1 FROM dbo.rptWinlostbyLeague WITH (NOLOCK) WHERE winlostdate = @Date)
	BEGIN
		DELETE dbo.rptWinlostbyLeague
		WHERE winlostdate = @Date
	END

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 3, 5, 25, 27)

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01'	-- half won/ half lose cut date

	;WITH cte_bettrans AS (
		SELECT
			a.winlostdate
			,ISNULL(a.matchid, ISNULL(a.oddsid, 0)) AS matchid
			,a.oddsid
			,a.odds
			,a.oddstype
			,a.bettype
			,SUM(ABS(a.stake)) AS stake
			,SUM(a.winlost - a.actual_stake) AS winlost
			,SUM(a.awinlost) AS awinlost
			,SUM(a.comm) AS comm
			,SUM(a.playercomm) AS playercomm
			,a.recommend
			,CASE
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.modds IN (-0.25, 0.25)
					-- Sportsbook
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9699)
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
			,COUNT(1) AS betcount
			,CASE 
				WHEN BA.transid IS NULL THEN 0
				WHEN BA.transid IS NOT NULL THEN 1
			END AS isBA
			,a.currency
			,a.liveindicator
		FROM bodb02.dbo.bettrans AS a WITH (NOLOCK)
			INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) AS LC ON a.recommend = lc.custid AND a.currency = lc.currency
			INNER JOIN @SportBettype AS s ON s.BetType = a.bettype
			LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON a.transid = ba.transid
		WHERE a.winlostdate = @Date
			AND a.statusID IN (111, 112, 113)
			AND a.bettype < 19999
			AND a.matchid >= 0
		GROUP BY a.matchid
			,a.recommend
			,a.bettype
			,a.odds
			,a.oddstype
			,a.oddsid
			,CASE
				WHEN a.winlostdate >= @HWHLCutDate
					AND a.statusID IN (112, 113)
					AND a.modds IN (-0.25, 0.25)
					-- Sportsbook
					AND (a.bettype < 999
						OR a.bettype BETWEEN 1301 AND 1399
						OR a.bettype BETWEEN 9001 AND 9399
						OR a.bettype BETWEEN 9400 AND 9699)
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
		,cte_raceinfo AS (
			SELECT o.Orid
				,r.LeagueID
			FROM bodb02.dbo.VSOutright AS o WITH (NOLOCK)
				INNER JOIN bodb02.dbo.VSRaceInfo AS r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE o.EventDate BETWEEN @Date AND DATEADD(DAY, 1, @Date)
		)
	INSERT INTO dbo.rptWinlostbyLeague (
		winlostdate
		,matchid
		,oddsid
		,odds
		,oddstype
		,bettype
		,stake
		,winlost
		,awinlost
		,comm
		,playercomm
		,recommend
		,LeagueID
		,statusID
		,betcount
		,isba
		,currency
		,LiveIndicator
		)
	SELECT
		a.winlostdate
		,a.matchid
		,a.oddsid
		,a.odds
		,a.oddstype
		,a.bettype
		,SUM(a.stake) AS stake
		,SUM(a.winlost) AS winlost
		,SUM(a.awinlost) AS awinlost
		,SUM(a.comm) AS comm
		,SUM(a.playercomm) AS playercomm
		,a.recommend
		,CASE 
			WHEN a.bettype IN (9, 29) THEN -9
			WHEN a.bettype = 2799 THEN -2799
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, -1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN ISNULL(r.LeagueID, -1)
			ELSE ISNULL(b.LeagueID, -1)
			END LeagueID
		,a.statusID
		,SUM(a.betcount) AS betcount
		,a.isba
		,a.currency
		,a.liveindicator
	FROM cte_bettrans AS a
		LEFT JOIN bodb02.dbo.match AS b WITH (NOLOCK) ON b.matchid = a.matchid
		LEFT JOIN cte_raceinfo AS r ON r.Orid = a.oddsid
		LEFT JOIN bodb02.dbo.outright AS ob WITH (NOLOCK) ON ob.orid = a.matchid
	GROUP BY a.winlostdate
		,a.matchid
		,a.oddsid
		,a.odds
		,a.oddstype
		,a.recommend
		,CASE 
			WHEN a.bettype IN (9, 29) THEN -9
			WHEN a.bettype = 2799 THEN -2799
			WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, -1)
			WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238) THEN ISNULL(r.LeagueID, -1)
			ELSE ISNULL(b.LeagueID, -1)
		END
		,a.statusID
		,a.bettype
		,a.isba
		,a.currency
		,a.liveindicator
END
GO