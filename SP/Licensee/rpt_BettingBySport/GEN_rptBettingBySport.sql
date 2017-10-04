USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingBySport]
    @FromDate smalldatetime,
    @ToDate smalldatetime
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
	WHERE rptDate BETWEEN @FromDate AND @ToDate

	-- Prepare Data for MuayThai Parlay
	DECLARE @MoveBetDate SMALLDATETIME, @TempFromDate SMALLDATETIME, @TempToDate SMALLDATETIME
	SELECT @MoveBetDate = MAX(winlostdate) FROM bodb02.dbo.bettrans14 (NOLOCK)

	DECLARE @tmpBettrans AS TABLE (transid BIGINT, NoOfSubParlay INT, NoOfMuayThai INT)

	SELECT @TempFromDate = CASE WHEN @FromDate <= @MoveBetDate THEN DATEADD(DAY,1, @MoveBetDate) ELSE @FromDate END
	SELECT @TempToDate = CASE WHEN @ToDate >= @MoveBetDate THEN @MoveBetDate ELSE @ToDate END

	CREATE TABLE #bettrans (transid BIGINT, winlostdate SMALLDATETIME, recommend INT, ProductID INT, SportType INT
							, currency TINYINT, statusid TINYINT, NoOfSubParlay SMALLMONEY, NoOfMuayThai SMALLINT, swinlost MONEY
							, mwinlost MONEY, awinlost MONEY, winlost MONEY, actual_stake MONEY, stake MONEY, scomm MONEY
							, tpositiontaking SMALLMONEY, customercategory SMALLINT)
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
	          customercategory
	        )	
	SELECT b.transid -- Parlay MuayThai ticket
			, b.winlostdate
			, b.recommend
			, 0 AS ProductID
			, 29 AS SportType
			, b.currency
			, b.statusid
			, b.hdp2 AS NoOfSubParlay
			, SUM (mu.NoOfMuayThai) AS NoOfMuayThai
			, b.swinlost 
			, b.mwinlost
			, b.awinlost
			, b.winlost
			, b.actual_stake
			, b.stake		
			, b.scomm 
			, b.tpositiontaking
			, b.customercategory		
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN 
				(
					SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
					FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						LEFT JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid	
					WHERE m.sporttype = 44 --AND m.eventstatus <> 'running' --AND m.eventdate BETWEEN @TempFromDate AND @ToDate
					GROUP BY bm.refno

					UNION ALL

					SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
					FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid	
					WHERE m.sporttype = 44 --AND bm.winlostdate BETWEEN @FromDate AND @TempToDate				
					GROUP BY bm.refno
				) mu ON mu.refno = b.refno
	WHERE b.bettype IN (9, 29) AND b.winlostdate BETWEEN @FromDate AND @ToDate
	GROUP BY b.transid, b.winlostdate, b.recommend, b.currency, b.statusid, b.hdp2 
		, b.swinlost, b.mwinlost, b.awinlost, b.winlost, b.actual_stake, b.stake, b.scomm, b.tpositiontaking, b.customercategory

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
			, b.customercategory
	FROM dbo.bettrans b with (nolock)
		INNER JOIN (
						SELECT matchid 
						FROM dbo.match WITH (NOLOCK) 
						WHERE eventdate BETWEEN @fromdate AND @todate AND SportType = 44
					) m ON b.matchid = m.matchid
	WHERE b.winlostdate BETWEEN @fromdate AND @todate

	CREATE CLUSTERED INDEX IDX_Index_BT ON #bettrans(recommend, winlostdate)	

	--For Muay Thai
	INSERT INTO dbo.rpt_BettingBySport(rptDate 
									   , SiteID 
									   , ProductID
									   , SportType 
									   , CurrencyId
									   , StatusId
									   , LicenseeWL
									   , CustomerWL
									   , Turnover
									   , BetCount
									   , WLShare
									   , CommissionS
									   , CommShare
									   , CustomerCategory)							   																	   
	SELECT	b.winlostdate AS rptDate
			, isnull(siteT.SiteID,-1) AS SiteID
			, 0 AS ProductID
			, 44 AS SportType
			, b.currency AS CurrencyId
			, b.statusid AS StatusId
			, case isnull(l.LabelID,0) when 0
				   then 0
				   else sum ((actual_stake - winlost - swinlost - mwinlost -  awinlost - scomm) * (b.NoOfMuayThai/b.NoOfSubParlay))
			  end as LicenseeWL
			, SUM((winlost - actual_stake) * (b.NoOfMuayThai/b.NoOfSubParlay)) AS CustomerWL -- Customer Winlosss
			, sum (stake) AS Turnover --Turnover
			, count (1) AS BetCount --Total Bets
			, sum(actual_stake - winlost) * 0.03 as WLShare -- Winloss Share with Muay Thai partner
			, -SUM((scomm) * (b.NoOfMuayThai/b.NoOfSubParlay)) as CommissionS -- Commission for Licensee
			, -sum(scomm * 0.03/(1 - tpositiontaking)) as CommShare -- Commission for Licensee share with Muay Thai partner
			, b.customercategory AS CustomerCategory
	FROM #bettrans b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
		LEFT JOIN bodb_Licensee.dbo.Labels l WITH (NOLOCK) ON SiteT.SiteID = l.LabelID	
	GROUP BY b.winlostdate, isnull(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, l.LabelID 
END  

