/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport]
    @Date smalldatetime
AS
/*
    Created: 20150226@Francis
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DBLIC.bodb_LicenseeReport

    Revisions:
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20170529@Paul: Get matchid from staging match table [Redmine: #72914]
	- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]
	- 20171114@Harper: Fix Date Range when get detail ticket 
	- 20180703@Sophia: Check @Date <= Movebetday will return because this day don't have data on Bettrans [Redmine: #97567]

	EXEC GEN_rptBettingBySport '2017-10-28'
*/ 
BEGIN

	IF @Date IS NULL
		RETURN
	
	DECLARE @Dates AS TABLE(BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @Dates(BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
		
	IF EXISTS (SELECT 1 FROM @Dates WHERE MoveBetsDay >= @Date)
	   RETURN
	

    DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate = @Date	

	DECLARE @ShareRate MONEY = 0.03

	CREATE TABLE #Match (MatchID INT)
	CREATE TABLE #tmpMuayThai (refno BIGINT, NoOfMuayThai INT)
	CREATE TABLE #tmpSubParlay (refno BIGINT, NoOfSubParlay SMALLMONEY)
	CREATE TABLE #tmpBettrans (transID BIGINT, NoOfMuayThai INT , NoOfSubParlay SMALLMONEY)
	CREATE TABLE #bettrans (transid BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai INT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT, IsParlay BIT)

	INSERT INTO #Match ( MatchID )
	SELECT m.matchid
	FROM bodb02.dbo.match m WITH (NOLOCK)
	WHERE m.sporttype = 44
	UNION
	SELECT m.matchid
	FROM bodb02.dbo.match14 m WITH (NOLOCK)
	WHERE m.sporttype = 44	

	-- bettransm
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )	
	SELECT bm.refno, COUNT(bm.transid)
	FROM #Match m 
		INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON m.MatchID = bm.matchid	
	WHERE bm.statusID NOT IN (101, 102, 103) -- reject, void, refund		
	GROUP BY bm.refno

	-- bettransm14
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )
	SELECT bm.refno, COUNT(bm.transid)
	FROM #Match m 
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON m.MatchID = bm.matchid
	WHERE bm.statusID NOT IN (101, 102, 103) 		
	GROUP BY bm.refno

	CREATE CLUSTERED INDEX IX_refno ON #tmpMuayThai (refno)

	IF EXISTS ( SELECT 1 FROM #tmpMuayThai ) -- If we have parlay muaythai
	BEGIN
		
		-- bettransm
		INSERT INTO #tmpSubParlay (refno,NoOfSubParlay)
		SELECT bm.refno, COUNT(bm.transid)
		FROM bodb02.dbo.bettransm bm WITH (NOLOCK) 			
		WHERE bm.statusID NOT IN (101, 102, 103)			
			AND EXISTS (SELECT 1 FROM #tmpMuayThai t WHERE bm.refno = t.refno)			 
		GROUP BY bm.refno

		-- bettransm14
		INSERT INTO #tmpSubParlay (refno,NoOfSubParlay)
		SELECT bm.refno, COUNT(bm.transid)
		FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)			
			AND EXISTS (SELECT 1 FROM #tmpMuayThai t WHERE bm.refno = t.refno)			
		GROUP BY bm.refno

		INSERT INTO #tmpBettrans ( transID, NoOfMuayThai, NoOfSubParlay )	
		SELECT b.transid, muay.NoOfMuayThai, sub.NoOfSubParlay
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN ( SELECT refno, SUM (NoOfMuayThai) AS NoOfMuayThai
						FROM #tmpMuayThai
						GROUP BY refno
					) muay ON b.refno = muay.refno	
			INNER JOIN ( SELECT refno, SUM (NoOfSubParlay) AS NoOfSubParlay
						FROM #tmpSubParlay
						GROUP BY refno
					) sub ON b.refno = sub.refno
		WHERE b.bettype IN (9, 29) AND b.matchid IN (9, 29)	
			AND b.statusID IN (111, 112, 113)
			AND b.winlostdate = @Date			
	END
	
	CREATE CLUSTERED INDEX IX_transid ON #tmpBettrans (transID)

	INSERT INTO #bettrans
	        ( transid ,
	          winlostdate ,
	          recommend ,
	          ProductID ,
	          SportType ,
	          currency ,
	          statusid ,
	          NoOfSubParlay ,
	          NoOfMuayThai ,
	          swinlost ,
	          mwinlost ,
	          awinlost ,
	          winlost ,
	          actual_stake ,
	          stake ,
	          scomm ,
	          tpositiontaking ,
	          customercategory,
			  IsParlay
	        )
	SELECT b.transid -- Parlay MuayThai ticket
			, b.winlostdate
			, b.recommend
			, 0 AS ProductID
			, 44 AS SportType
			, b.currency
			, b.statusid
			, t.NoOfSubParlay AS NoOfSubParlay
			, t.NoOfMuayThai AS NoOfMuayThai
			, b.swinlost 
			, b.mwinlost
			, b.awinlost
			, b.winlost
			, b.actual_stake
			, b.stake		
			, b.scomm 
			, b.tpositiontaking
			, CASE   WHEN b.recommend = 52466 THEN 27 --8RM
						WHEN b.recommend = 5707545 THEN 28 	--BARM
			ELSE -1 END	AS Customercategory
			, 1 -- Parlay of MuayThai
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #tmpBettrans t ON t.transID = b.transid

	UNION ALL
	
	SELECT	b.transid -- Single MuayThai Ticket
			, b.winlostdate
			, b.recommend
			, 0 AS ProductID
			, 44 AS SportType
			, b.currency 
			, b.statusid 
			, 1 AS NoOfSubParlay
			, 1 AS NoOfMuayThai
			, swinlost 
			, mwinlost
			, awinlost
			, winlost
			, actual_stake
			, stake		
			, scomm 
			, tpositiontaking
			, CASE   WHEN b.recommend = 52466 THEN 27 --8RM
						WHEN b.recommend = 5707545 THEN 28 	--BARM
			ELSE -1 END AS Customercategory
			, 0 -- Single Ticket of MuayThai
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #Match m ON b.matchid = m.matchid
	WHERE ( b.bettype < 31
			OR b.bettype BETWEEN 121 AND 999
			OR b.Bettype BETWEEN 1301 and 1399 --new tennis's bettypes
		) 
		AND b.statusID IN (111, 112, 113)
		AND b.winlostdate = @Date

	-- Insert data to sum table
	INSERT INTO dbo.rpt_BettingBySport( rptDate 
									   , SiteID 
									   , ProductID
									   , SportType 
									   , CurrencyId
									   , StatusId	
									   , LicenseeWL
									   , AdjustedLicenseeWL
									   , CustomerWL
									   , AdjustedCustomerWL
									   , Turnover
									   , BetCount
									   , WLShare
									   , CommissionS
									   , AdjustedCommissionS
									   , CommShare
									   , AdjustedCommShare
									   , CustomerCategory
									   , IsParlay
									)	
	SELECT	b.winlostdate AS rptDate
			, ISNULL(siteT.SiteID,-1) AS SiteID
			, ProductID AS ProductID
			, SportType AS SportType
			, b.currency AS CurrencyId
			, b.statusid AS StatusId
			, CASE ISNULL(ibcsite.isDeposit, 1) WHEN 1
				   THEN 0
				   ELSE SUM (actual_stake - winlost - swinlost - mwinlost -  awinlost - scomm)
			  END AS LicenseeWL
			, CASE ISNULL(ibcsite.isDeposit, 1) WHEN 1
				   THEN 0
				   ELSE SUM ((actual_stake - winlost - swinlost - mwinlost -  awinlost - scomm) * (b.NoOfMuayThai/b.NoOfSubParlay))
			  end as LicenseeWLParlay
			, SUM(winlost - actual_stake) AS CustomerWL -- Customer Winlosss
			, SUM((winlost - actual_stake) * (b.NoOfMuayThai/b.NoOfSubParlay)) AS CustomerWLParlay
			, SUM (stake) AS Turnover --Turnover
			, COUNT (1) AS BetCount --Total Bets
			, SUM(actual_stake - winlost) as WLShare -- Winloss Share with Muay Thai partner
			, -SUM(scomm) AS CommissionS -- Commission for Licensee
			, -SUM((scomm) * (b.NoOfMuayThai/b.NoOfSubParlay)) AS CommissionSParlay 
			, -SUM(@ShareRate / (1 - tpositiontaking) * scomm) as CommShare -- Commission for Licensee share with Muay Thai partner
			, -SUM(@ShareRate / (1 - tpositiontaking) * scomm * (b.NoOfMuayThai/b.NoOfSubParlay) ) as CommShareParlay
			, b.customercategory AS CustomerCategory
			, b.IsParlay
	FROM #bettrans b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID		
	GROUP BY b.winlostdate, ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit 
			, ProductID, b.SportType, IsParlay
	
	DROP TABLE #bettrans
	DROP TABLE #tmpBettrans
	DROP TABLE #Match
	DROP TABLE #tmpMuayThai
END  
GO
