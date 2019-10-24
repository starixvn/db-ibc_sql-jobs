/*<info serverAlias="DBLIC-bodb_LicenseeReport" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptCustomerMatch_Bettrans14] 
	@Date SMALLDATETIME
AS
/*	
	Created: 20131125@Florent Nguyen
	Task: Customer Performance Report
	DB: DBLIC.bodb_LicenseeReport
	
	Revision:
		- 20141121@Don: Adjustment to serve to change KeenOcean's currency RMB to HK$
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20180814@Joseph: Remove Racing [RedmineID: #99378]
		- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_bk [RedmineID: #103656]
	
	Parameter's Explanation:			
*/
BEGIN
SET NOCOUNT ON;
	--DECLARE @Fromdate DATETIME,
	--	@Todate DATETIME
	--SELECT @Fromdate='2013-10-17',@todate='2013-10-17'
IF exists(SELECT TOP 1 1 FROM dbo.rptCustomerMatch AS rct WITH (NOLOCK) WHERE rct.winlostdate=@date)
	BEGIN
		DELETE dbo.rptCustomerMatch WHERE winlostdate=@Date
	END 	

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date

;WITH cte_bettrans
AS (
	SELECT a.CustID		
		,a.recommend
		,a.matchid
		,a.oddsid
		,a.bettype
		,SUM(ABS(a.stake)) as stake
		,sum(a.winlost- a.actual_stake) winlost		
		,a.Odds
		,a.oddstype
		,CASE
			WHEN a.winlostdate >= @HWHLCutDate AND a.statusID IN(112,113) AND a.modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (a.bettype < 999 OR a.bettype BETWEEN 1301 AND 1399 OR a.bettype BETWEEN 9001 AND 9399)
				AND a.bettype NOT IN (29,38,911,912,913,914 )  --- Parlay, betbuilder, Cashout        
				AND a.bettype NOT BETWEEN 81 AND 120
			THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
			WHEN a.winlostdate < @HWHLCutDate AND a.statusID IN (112,113)
				AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
				AND ABS(modds) = 0.25
			THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
			ELSE a.statusID
			END AS statusID
		,a.winlostdate
		,COUNT(a.custid) betcount
		,CASE 
		WHEN BA.transid IS NULL THEN 0
		WHEN BA.transid IS NOT NULL THEN 1 END AS isBA
		,sum(awinlost) awinlost
		,sum(comm) comm
		,sum(playercomm) playercomm
		,a.currency
	FROM bodb02.dbo.bettrans14 a WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) LC ON a.recommend = lc.custid AND a.currency = lc.currency
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_bk BA WITH (NOLOCK) ON a.transid = ba.transid
	WHERE a.winlostdate =@date 
			AND a.statusID IN (111, 112, 113)
	GROUP BY a.CustID		
		,a.recommend
		,a.matchid
		,a.oddsid
		,a.bettype
		,a.Odds
		,a.oddstype
		,CASE
			WHEN a.winlostdate >= @HWHLCutDate AND a.statusID IN(112,113) AND a.modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (a.bettype < 999 OR a.bettype BETWEEN 1301 AND 1399 OR a.bettype BETWEEN 9001 AND 9399)
				AND a.bettype NOT IN (29,38,911,912,913,914 )  --- Parlay, betbuilder, Cashout        
				AND a.bettype NOT BETWEEN 81 AND 120
			THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
			WHEN a.winlostdate < @HWHLCutDate AND a.statusID IN (112,113)
				AND a.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485)
				AND ABS(modds) = 0.25
			THEN CASE WHEN a.statusID = 112 THEN 114 ELSE 115 END
			ELSE a.statusID
			END
		,a.winlostdate
		,CASE 
		WHEN BA.transid IS NULL THEN 0
		WHEN BA.transid IS NOT NULL THEN 1 END
		,a.currency
	)
	,cte_raceinfo
AS (
	SELECT o.Orid
		,r.SportType
		,r.LeagueID
	FROM bodb02.dbo.VSOutright14 o WITH (NOLOCK)
	INNER JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
	WHERE EventDate =@Date
	)
INSERT INTO dbo.rptCustomerMatch (
	 CustID
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
	,Comm
	,playercomm
	,recommend
	,isba		
	,betcount
	,currency)
SELECT a.CustID
	,a.matchid
	,a.oddsid
	,CASE 
		WHEN a.bettype IN (9, 29) THEN - 9
		WHEN a.bettype = 2799 THEN -2799
		WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, - 1)
		WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238)
			THEN isnull(result.LeagueID,-1)
		ELSE isnull(b.LeagueID, - 1)
		END LeagueID
	,a.bettype
	,a.Odds
	,a.oddstype
	,a.statusID
	,sum(stake)stake
	,sum(winlost) winlost  
	,winlostdate	
	,sum(awinlost) awinlost
	,sum(comm) Comm
	,sum(playercomm) playercomm
	,a.recommend
	,a.isba		
	,sum(a.betcount) betcount
	,a.currency
FROM cte_bettrans a
	LEFT JOIN bodb02.dbo.match14 b WITH (NOLOCK) ON a.matchid = b.matchid
	LEFT JOIN cte_raceinfo result ON a.oddsid = result.Orid
	LEFT JOIN bodb02.dbo.outright14 AS ob WITH (NOLOCK) ON a.matchid = ob.orid
GROUP BY a.CustID
	,a.matchid
	,a.oddsid
	,a.bettype
	,a.Odds
	,a.oddstype
	,a.statusID
	,winlostdate	
	,a.recommend
	,a.isba
	,CASE 
		WHEN a.bettype IN (9, 29) THEN - 9
		WHEN a.bettype = 2799 THEN -2799
		WHEN a.bettype = 10 THEN ISNULL(ob.leagueid, - 1)
		WHEN a.bettype IN (1231, 1232, 1233, 1237, 1238)
			THEN isnull(result.LeagueID,-1)
		ELSE isnull(b.LeagueID, - 1)
		END 
	,a.currency
END

GO