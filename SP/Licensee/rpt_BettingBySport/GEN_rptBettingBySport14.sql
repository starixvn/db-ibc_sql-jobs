USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport14]
    @Date smalldatetime
AS
/*
    Created: 20170930@Harper
    Task: Generate data for bodb_LicenseeReport.dbo.rpt_BettingBySport (for Muay Thai)
    DB: DB052.bodb_LicenseeReport

    Revisions:	
		- 20170930@Harper: Get more info for MuayThai Parlay [Redmine: #82827]
*/ 
BEGIN
    DELETE FROM dbo.rpt_BettingBySport
	WHERE rptDate = @Date

	CREATE TABLE #tmpBettransm (refno BIGINT, NoOfMuayThai INT, NoOfSubParlay SMALLMONEY, IsBettran BIT)
	CREATE TABLE #Match (MatchID INT PRIMARY KEY)
	CREATE TABLE #bettrans (transid BIGINT, refno BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai INT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT, IsExists BIT)
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
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
	WHERE b.bettype IN (9, 29) AND b.matchid IN (9, 29) AND b.statusID IN (111, 112, 113) -- win, lose, raw
		AND b.winlostdate = @Date

	CREATE CLUSTERED INDEX [IX_refno] ON #bettrans ([refno] ASC)		

	INSERT INTO #tmpBettransm ( refno, NoOfMuayThai )	
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
	FROM #bettrans b
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE m.sporttype = 44 AND bm.statusID NOT IN (101, 102, 103) -- reject, void, refund		
	GROUP BY bm.refno
	
	INSERT INTO #tmpBettransm ( refno, NoOfMuayThai, IsBettran )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai, 1
	FROM #bettrans b 
		INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON bm.refno = b.refno
		INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid	
	WHERE m.sporttype = 44 AND bm.statusID NOT IN (101, 102, 103)
	GROUP BY bm.refno
	
	-- Handle data for bettransM_BK		
	CREATE TABLE #tmpBK (refno BIGINT, transID BIGINT, matchID INT)

	IF EXISTS ( SELECT 1 
				FROM #bettrans b
					INNER JOIN #tmpBettransm bm ON b.refno = bm.refno
				WHERE ISNULL(bm.IsBettran, 0) = 0
			)
	BEGIN
		DECLARE @maxDate SMALLDATETIME
		SELECT @maxDate = MAX(winlostdate) FROM DBARC.bodb_Archive.dbo.bettransm WITH (NOLOCK)

		INSERT INTO #Match ( MatchID )	
		SELECT m.matchid
		FROM DBARC.bodb_Archive.dbo.match_bk m WITH (NOLOCK)
		WHERE m.sporttype = 44 AND m.eventdate >= DATEADD(DAY, -14, @maxDate)

		UPDATE b
		SET b.IsExists = t.IsBettran
		FROM #bettrans b
			INNER JOIN #tmpBettransm t ON b.refno = t.refno		
					
		INSERT INTO #tmpBK ( refno, transID, matchID )		
		SELECT bm.refno, bm.transid, bm.matchid
		FROM DBARC.bodb_Archive.dbo.bettransm bm WITH (NOLOCK)
			INNER JOIN #bettrans b ON bm.refno = b.refno
		WHERE bm.winlostdate >= DATEADD(DAY, -14, @maxDate) 
			AND bm.statusID NOT IN (101, 102, 103)

		CREATE CLUSTERED INDEX [IX_refnoBK] ON #tmpBK ([refno])

		INSERT INTO #tmpBettransm( refno, NoOfMuayThai)
		SELECT bk.refno, COUNT(bk.transID)
		FROM #bettrans b
			INNER JOIN #tmpBK bk ON b.refno = bk.refno
			INNER JOIN #Match m ON bk.matchID = m.MatchID
		WHERE ISNULL(b.IsExists, 0) = 0
		GROUP BY bk.refno

		;WITH selection AS
		( 
			SELECT bm.refno, COUNT(bm.transid) AS NoOfSubParlay
			FROM #tmpBettransm b
				INNER JOIN #tmpBK bm WITH (NOLOCK) ON b.refno = bm.refno	
			GROUP BY bm.refno
		)
		UPDATE b
		SET b.NoOfSubParlay = bm.NoOfSubParlay
		FROM #tmpBettransm b
			INNER JOIN selection bm ON b.refno = bm.refno	
		
		DROP TABLE #tmpBK
		DROP TABLE #Match
	END	

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
	),
	subParlay AS
	(
		SELECT t.refno, SUM(ISNULL(s.NoOfSubParlay, 0)) AS NoOfSubParlay
		FROM selection s
			INNER JOIN #tmpBettransm t ON s.refno = t.refno
		GROUP BY t.refno
	)
	UPDATE b
	SET b.NoOfSubParlay = p.NoOfSubParlay
	FROM #tmpBettransm b
		INNER JOIN subParlay p ON b.refno = p.refno

	UPDATE b
	SET b.NoOfMuayThai = bm.NoOfMuayThai,
		b.NoOfSubParlay = bm.NoOfSubParlay
	FROM #bettrans b
		INNER JOIN (
						SELECT refno, SUM (NoOfMuayThai) AS NoOfMuayThai, SUM (NoOfSubParlay) AS NoOfSubParlay
						FROM #tmpBettransm
						GROUP BY refno
				) bm ON b.refno = bm.refno	

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
			WHERE ISNULL(b.NoOfMuayThai, 0) <> 0
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
					) 
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate = @Date 
			) b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
		--LEFT JOIN bodb_Licensee.dbo.Labels l WITH (NOLOCK) ON SiteT.SiteID = l.LabelID	
	GROUP BY b.winlostdate, ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit
			, ProductID, b.SportType, b.IsParlay

	DROP TABLE #bettrans
	DROP TABLE #tmpBettransm	
END  

