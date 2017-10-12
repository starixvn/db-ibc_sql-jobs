USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport]
    @Date smalldatetime
AS
/*
    Created: 20150226@Francis
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DB052.bodb_LicenseeReport

    Revisions:
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20170529@Paul: Get matchid from staging match table [Redmine: #72914]
	- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]
*/ 
BEGIN
    DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate = @Date

	CREATE TABLE #Match (MatchID INT)
	CREATE TABLE #tmpBettransm (refno BIGINT, NoOfMuayThai INT, NoOfSubParlay SMALLMONEY)
	CREATE TABLE #tmpBettrans (transID BIGINT, NoOfMuayThai INT , NoOfSubParlay SMALLMONEY)
	CREATE TABLE #bettrans (transid BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai INT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT, IsParlay BIT)

	INSERT INTO #Match ( MatchID )
	SELECT m.matchid
	FROM bodb02.dbo.match m WITH (NOLOCK)
	WHERE m.sporttype = 44
	UNION ALL
	SELECT m.matchid
	FROM bodb02.dbo.match14 m WITH (NOLOCK)
	WHERE m.sporttype = 44	

	INSERT INTO #tmpBettransm ( refno, NoOfMuayThai )	
	SELECT b.refno, COUNT(b.transid) AS NoOfMuayThai
	FROM
		(
			SELECT bm.refno, bm.transid
			FROM #Match m 
				INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON m.MatchID = bm.matchid	
			WHERE bm.statusID NOT IN (101, 102, 103) -- reject, void, refund
			UNION ALL
			SELECT bm.refno, bm.transid
			FROM #Match m 
				INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON m.MatchID = bm.matchid
			WHERE bm.statusID NOT IN (101, 102, 103) 
		) AS b
	GROUP BY b.refno

	CREATE CLUSTERED INDEX IX_refno ON #tmpBettransm (refno)

	;WITH selection AS
	(   
		SELECT b.refno, COUNT(b.transid) AS NoOfSubParlay
		FROM
			(
				SELECT bm.refno, bm.transid
				FROM #tmpBettransm b
					INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno	
				WHERE bm.statusID NOT IN (101, 102, 103)
				UNION ALL
				SELECT bm.refno, bm.transid
				FROM #tmpBettransm b 
					INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno	
				WHERE bm.statusID NOT IN (101, 102, 103)
			) AS b
		GROUP BY b.refno
	)
	UPDATE b
	SET b.NoOfSubParlay = bm.NoOfSubParlay
	FROM #tmpBettransm b
		INNER JOIN selection bm ON b.refno = bm.refno

	INSERT INTO #tmpBettrans ( transID, NoOfMuayThai, NoOfSubParlay )	
	SELECT b.transid, bm.NoOfMuayThai, bm.NoOfSubParlay
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #tmpBettransm bm ON b.refno = bm.refno
	WHERE b.bettype IN (9, 29) AND b.matchid IN (9, 29)	
		AND b.statusID IN (111, 112, 113)
		AND b.winlostdate = @Date			

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
									   , LicenseeWLOfParlay
									   , CustomerWL
									   , CustomerWLOfParlay
									   , Turnover
									   , BetCount
									   , WLShare
									   , CommissionS
									   , CommissionSOfParlay
									   , CommShare
									   , CommShareOfParlay
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
			, -SUM(scomm * (1 - tpositiontaking)) as CommShare -- Commission for Licensee share with Muay Thai partner
			, -SUM(scomm * (b.NoOfMuayThai/b.NoOfSubParlay) * (1 - tpositiontaking)) as CommShareParlay
			, b.customercategory AS CustomerCategory
			, b.IsParlay
	FROM #bettrans b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
		--LEFT JOIN bodb_Licensee.dbo.Labels l WITH (NOLOCK) ON SiteT.SiteID = l.LabelID	
	GROUP BY b.winlostdate, ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit 
			, ProductID, b.SportType, IsParlay
	
	DROP TABLE #bettrans
	DROP TABLE #tmpBettrans
	DROP TABLE #Match
	DROP TABLE #tmpBettransm
END  

