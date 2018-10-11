/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptCustomerMatch_Bettrans14] 
	@Date SMALLDATETIME
AS
/*	
	Created	: Florent Nguyen
	Task: Customer Performance Report  
	Date: 2013-11-25
	DB: DBLIC.bodb_LicenseeReport
	Original:   
	Revision:
		- 20141121@Don: Adjustment to serve to change KeenOcean's currency RMB to HK$
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20180814@Joseph: Remove Racing [RedmineID: #99378]
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
		WHEN a.statusID = 112
			AND a.bettype IN (1, 3, 7, 8, 17, 18)
			AND ABS(modds) = 0.25
			THEN 114
		WHEN a.statusID = 113
			AND a.bettype IN (1, 3, 7, 8, 17, 18)
			AND ABS(modds) = 0.25
			THEN 115
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
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON a.transid = ba.transid
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
		WHEN a.statusID = 112
			AND a.bettype IN (1, 3, 7, 8, 17, 18)
			AND ABS(modds) = 0.25
			THEN 114
		WHEN a.statusID = 113
			AND a.bettype IN (1, 3, 7, 8, 17, 18)
			AND ABS(modds) = 0.25
			THEN 115
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