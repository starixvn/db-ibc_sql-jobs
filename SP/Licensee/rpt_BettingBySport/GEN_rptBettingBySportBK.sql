/*<info serverAlias="DBARC-bodb_archive" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_archive]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySportBK]
    @Date smalldatetime
AS
/*
    Created: 20170930@Harper
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DBARC.bodb_archive

    Revisions:	
		- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]

	GEN_rptBettingBySportBK '2017-09-30'
*/ 
BEGIN
    --DELETE FROM DBLIC.bodb_LicenseeReport.dbo.rpt_BettingBySport
	--WHERE rptDate = @Date

	DECLARE @MoveBetsDay	SMALLDATETIME, 
			@BalanceUpDay	SMALLDATETIME
	DECLARE @tmpdate		TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME) 

	INSERT INTO @tmpdate(BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tmpdate

	CREATE TABLE #tmpMuayThai (refno BIGINT, NoOfMuayThai INT, IsBettran BIT)	
	CREATE TABLE #tmpSubParlay (refno BIGINT, NoOfSubParlay SMALLMONEY)
	CREATE TABLE #bettrans (transid BIGINT, refno BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai INT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT, IsExists BIT)

	DECLARE @Sitelist AS TABLE (IbcSiteID INT, SiteID INT)	
	INSERT INTO @Sitelist (IbcSiteID, SiteID)
	SELECT IbcSiteID, SiteID
	FROM OPENQUERY(DBLIC, 'SELECT IbcSiteID, SiteID FROM bodb_Licensee.dbo.view_site_list')	

	INSERT INTO #bettrans
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
			, 0 AS SportType
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
	FROM bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)
	WHERE b.bettype IN (9, 29) AND b.matchid IN (9, 29) AND b.statusID IN (111, 112, 113) -- win, lose, raw
		AND b.winlostdate = @Date

	CREATE CLUSTERED INDEX [IX_refno] ON #bettrans ([refno] ASC)		

	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
	FROM #bettrans b
		INNER JOIN bodb_archive.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN bodb_archive.dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE m.sporttype = 44 AND bm.statusID NOT IN (101, 102, 103) -- reject, void, refund	
		AND bm.winlostdate < @BalanceUpDay 	
	GROUP BY bm.refno
	
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
	FROM #bettrans b 
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON bm.refno = b.refno
		INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid	
	WHERE m.sporttype = 44 AND bm.statusID NOT IN (101, 102, 103)
		AND bm.winlostdate >= @BalanceUpDay AND bm.winlostdate <= @MoveBetsDay
	GROUP BY bm.refno	

	IF EXISTS (SELECT 1 FROM #tmpMuayThai)
	BEGIN
		INSERT INTO #tmpSubParlay( refno, NoOfSubParlay )	
		SELECT bm.refno, COUNT(bm.transid) AS NoOfSubParlay
		FROM bodb_archive.dbo.bettransm bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)
			AND EXISTS (SELECT 1 FROM #tmpMuayThai muay WHERE bm.refno = muay.refno)
			AND bm.winlostdate < @BalanceUpDay 	
		GROUP BY bm.refno

		INSERT INTO #tmpSubParlay( refno, NoOfSubParlay )	
		SELECT bm.refno, COUNT(bm.transid) AS NoOfSubParlay
		FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)
			AND EXISTS (SELECT 1 FROM #tmpMuayThai muay WHERE bm.refno = muay.refno)
			AND bm.winlostdate >= @BalanceUpDay 	
		GROUP BY bm.refno					

		DELETE b
		FROM #bettrans b
		WHERE NOT EXISTS (SELECT 1 FROM #tmpMuayThai muay WHERE b.refno = muay.refno)
		
		UPDATE b
		SET b.NoOfMuayThai = muay.NoOfMuayThai,
			b.NoOfSubParlay = sub.NoOfSubParlay
		FROM #bettrans b
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
		DELETE #bettrans		
	END		

	INSERT INTO ##rpt_BettingBySport_Temp( rptDate 
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
			, -SUM(scomm * (1 - tpositiontaking)) as CommShare -- Commission for Licensee share with Muay Thai partner
			, -SUM(scomm * (b.NoOfMuayThai/b.NoOfSubParlay) * (1 - tpositiontaking)) as CommShareParlay
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
			FROM #bettrans b			
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
			FROM bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)
				INNER JOIN bodb_archive.dbo.match_bk m WITH (NOLOCK) ON b.matchid = m.matchid
			WHERE m.sporttype = 44
				AND ( b.bettype < 31
						OR b.bettype BETWEEN 121 AND 999
						OR b.Bettype BETWEEN 1301 and 1399 --new tennis's bettypes
					) 
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate = @Date 
			) b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN @Sitelist siteT ON ibcsite.siteid = siteT.IbcSiteID
		--LEFT JOIN bodb_Licensee.dbo.Labels l WITH (NOLOCK) ON SiteT.SiteID = l.LabelID	
	GROUP BY b.winlostdate, ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit
			, ProductID, b.SportType, b.IsParlay

	DROP TABLE #bettrans
	DROP TABLE #tmpMuayThai
	DROP TABLE #tmpSubParlay	
END  
GO
--DROP TABLE ##rpt_BettingBySport_Temp