/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport14]
    @Date smalldatetime
AS
/*
    Created: 20170930@Harper
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DBLIC.bodb_LicenseeReport

    Revisions:	
		- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]
		- 20171114@Harper: Fix Date Range when get detail ticket
		- 20190311@Parsons: Implement BetBuilder [Redmine: #108995]		

	GEN_rptBettingBySport14 '2017-10-13'
*/ 
BEGIN
    DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate = @Date	

	DECLARE @ShareRate MONEY = 0.03

	CREATE TABLE #tmpMuayThai (refno BIGINT, NoOfMuayThai INT, IsBettran BIT)	
	CREATE TABLE #tmpSubParlay (refno BIGINT, NoOfSubParlay SMALLMONEY)
	CREATE TABLE #tmpbettrans (transid BIGINT, refno BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai INT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT, IsExists BIT)
	INSERT INTO #tmpbettrans
	        ( transid ,
	          refno ,
	          winlostdate ,
	          recommend ,
	          ProductID ,
	          SportType ,
	          currency ,
	          statusid ,
	          NoOfSubParlay ,	          
	          swinlost ,
	          mwinlost ,
	          awinlost ,
	          winlost ,
	          actual_stake ,
	          stake ,
	          scomm ,
	          tpositiontaking ,
	          customercategory
	        )	
	SELECT b.transid -- Parlay MuayThai ticket
			, b.refno
			, b.winlostdate
			, b.recommend
			, 0 AS ProductID
			, 44 AS SportType
			, b.currency
			, b.statusid
			, b.hdp2			
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
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
	WHERE b.bettype IN (9, 29) AND b.matchid IN (9, 29) AND b.statusID IN (111, 112, 113) -- win, lose, raw
		AND b.winlostdate = @Date

	CREATE CLUSTERED INDEX [IX_refno] ON #tmpbettrans ([refno] ASC)	
		
	-- bettransm14
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
	FROM #tmpbettrans b
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno		
	WHERE bm.oddsspread = 44 AND bm.statusID NOT IN (101, 102, 103) -- reject, void, refund	
	GROUP BY bm.refno

	-- bettransm
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai, IsBettran )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai, 1
	FROM #tmpbettrans b 
		INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON bm.refno = b.refno		
	WHERE bm.oddsspread = 44 AND bm.statusID NOT IN (101, 102, 103)		
	GROUP BY bm.refno
	
	-- Handle data for bettransM_BK		
	CREATE TABLE #tmpBK (refno BIGINT, transID BIGINT, matchID INT, oddsspread MONEY)
	CREATE TABLE #MatchBK (MatchID INT PRIMARY KEY)
	CREATE TABLE #bettransmBK (refno BIGINT PRIMARY KEY)

	INSERT INTO #bettransmBK ( refno )
	SELECT DISTINCT b.refno
	FROM #tmpbettrans b
		LEFT JOIN #tmpMuayThai t ON b.refno = t.refno	
	WHERE ISNULL(t.IsBettran, 0) = 0	

	IF EXISTS ( SELECT 1 FROM #bettransmBK b)
	BEGIN	
		INSERT INTO #MatchBK ( MatchID )	
		SELECT m.matchid
		FROM DBARC.bodb_Archive.dbo.match_bk m WITH (NOLOCK)
		WHERE m.sporttype = 44 
			AND m.eventdate >= DATEADD(DAY, -14, @Date)

		IF EXISTS (SELECT 1 FROM #MatchBK)
		BEGIN					
			INSERT INTO #tmpBK ( refno, transID, matchID, oddsspread )		
			SELECT bm.refno, bm.transid, bm.matchid, bm.oddsspread
			FROM DBARC.bodb_Archive.dbo.bettransm bm WITH (NOLOCK)
				INNER JOIN #bettransmBK b ON bm.refno = b.refno
			WHERE bm.winlostdate >= DATEADD(DAY, -14, @Date) 				
				AND bm.statusID NOT IN (101, 102, 103)

			CREATE CLUSTERED INDEX [IX_refnoBK] ON #tmpBK ([refno])

			INSERT INTO #tmpMuayThai( refno, NoOfMuayThai)
			SELECT bk.refno, COUNT(bk.transID)
			FROM #tmpBK bk
			WHERE bk.oddsspread = 44
			GROUP BY bk.refno			

			INSERT INTO #tmpSubParlay ( refno, NoOfSubParlay )		
			SELECT bm.refno, COUNT(bm.transid) AS NoOfSubParlay
			FROM #tmpBK bm
			WHERE EXISTS (SELECT 1 FROM #tmpMuayThai muay WHERE bm.refno = muay.refno)				
			GROUP BY bm.refno	
				
		END
		DROP TABLE #tmpBK
		DROP TABLE #MatchBK
		DROP TABLE #bettransmBK
	END	

	IF EXISTS (SELECT 1 FROM #tmpMuayThai)
	BEGIN
		INSERT INTO #tmpSubParlay( refno, NoOfSubParlay )	
		SELECT bm.refno, COUNT(bm.transid)
		FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)
			AND EXISTS (SELECT 1 FROM #tmpMuayThai t WHERE bm.refno = t.refno)			
		GROUP BY bm.refno

		INSERT INTO #tmpSubParlay( refno, NoOfSubParlay )	
		SELECT bm.refno, COUNT(bm.transid)
		FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)
			AND EXISTS (SELECT 1 FROM #tmpMuayThai t WHERE bm.refno = t.refno)			
		GROUP BY bm.refno
	
		DELETE b
		FROM #tmpbettrans b
		WHERE NOT EXISTS (SELECT 1 FROM #tmpMuayThai muay WHERE b.refno = muay.refno)

		UPDATE b
		SET b.NoOfMuayThai = muay.NoOfMuayThai,
			b.NoOfSubParlay = sub.NoOfSubParlay
		FROM #tmpbettrans b
			INNER JOIN ( SELECT refno, SUM (NoOfMuayThai) AS NoOfMuayThai
						 FROM #tmpMuayThai
						 GROUP BY refno
					) muay ON b.refno = muay.refno	
			INNER JOIN ( SELECT refno, SUM (NoOfSubParlay) AS NoOfSubParlay
						 FROM #tmpSubParlay
						 GROUP BY refno
					) sub ON b.refno = sub.refno
	END
	ELSE
	BEGIN
		DELETE #tmpbettrans
	END

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
			  END AS LicenseeWL -- House Income
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
	FROM (
			SELECT b.transid -- Parlay MuayThai ticket
					, b.winlostdate
					, b.recommend
					, 0 AS ProductID
					, 44 AS SportType
					, b.currency
					, b.statusid
					, b.NoOfSubParlay
					, b.NoOfMuayThai 
					, b.swinlost 
					, b.mwinlost
					, b.awinlost
					, b.winlost
					, b.actual_stake
					, b.stake		
					, b.scomm 
					, b.tpositiontaking
					, b.customercategory
					, 1 AS IsParlay
			FROM #tmpbettrans b			
			UNION ALL
			SELECT b.transid -- Single MuayThai Ticket
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
					, 0 AS IsParlay
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON b.matchid = m.matchid
			WHERE m.sporttype = 44
				AND ( b.bettype < 31
						OR b.bettype BETWEEN 121 AND 999
						OR b.Bettype BETWEEN 1301 and 1399 --new tennis's bettypes
						OR b.bettype = 38 -- BetBuilder
					) 
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate = @Date 
			) b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
	GROUP BY b.winlostdate, ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit
			, ProductID, b.SportType, b.IsParlay

	DROP TABLE #tmpbettrans
	DROP TABLE #tmpMuayThai
	DROP TABLE #tmpSubParlay	
END  
GO