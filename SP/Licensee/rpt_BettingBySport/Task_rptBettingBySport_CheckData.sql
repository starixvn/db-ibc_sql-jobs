USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptBettingBySport_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT, --0: No mismatch; 1: Has real currencies; 2: UUS only
	@IsParlay			VARCHAR(5) OUTPUT -- 0: single ticket; 1: parlay ticket
AS

/*
	Created: 20170523@Paul
	Task : Check & correct data of rptBettingBySport
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
		- 20171018@Harper: Include Parlay MuayThai to check data [RedmineID #82827]

	DECLARE @HasDataMismatch TINYINT, @IsParlay VARCHAR(5)
	EXEC Task_rptBettingBySport_CheckData @WinlostDate = '2017-09-29', @HasDataMismatch = @HasDataMismatch OUTPUT, @IsParlay = @IsParlay OUTPUT
	SELECT @HasDataMismatch, @IsParlay
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source
	(
		SiteID				INT,
		CurrencyId			INT,
		StatusId			SMALLINT,
		LicenseeWL			MONEY,
		CustomerWL			MONEY,
		Turnover			MONEY,
		BetCount			INT,
		CommissionS			MONEY,
		CommShare			MONEY,
		AdjustedLicenseeWL  MONEY,
		AdjustedCustomerWL  MONEY,
		AdjustedCommissionS MONEY,
		AdjustedCommShare   MONEY,
		CustomerCategory	INT,
		IsParlay			BIT
	);

	CREATE TABLE #Target
	(
		SiteID				INT,
		CurrencyId			INT,
		StatusId			SMALLINT,
		LicenseeWL			MONEY,
		CustomerWL			MONEY,
		Turnover			MONEY,
		BetCount			INT,
		CommissionS			MONEY,
		CommShare			MONEY,
		AdjustedLicenseeWL  MONEY,
		AdjustedCustomerWL  MONEY,
		AdjustedCommissionS MONEY,
		AdjustedCommShare   MONEY,
		CustomerCategory	INT,
		IsParlay			BIT
	);

	CREATE TABLE #Log
	(
		TableName	VARCHAR(100), 
		IsSource	BIT, 
		CurrencyId	INT, 
		Turnover	MONEY, 
		Winloss		MONEY, 
		BetCount	INT, 
		ExtraInfo	VARCHAR(MAX),
		IsParlay	BIT
	)

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;
				
	
	-- Source
	DECLARE @MoveBetsDay	SMALLDATETIME, 
			@BalanceUpDay	SMALLDATETIME
	DECLARE @tmpdate		TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME) 

	INSERT INTO @tmpdate(BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tmpdate

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
		AND b.winlostdate = @WinlostDate

	CREATE CLUSTERED INDEX [IX_refno] ON #tmpbettrans ([refno] ASC)	
		
	-- bettransm14
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai
	FROM #tmpbettrans b
		INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno		
	WHERE bm.oddsspread = 44 AND bm.statusID NOT IN (101, 102, 103) -- reject, void, refund	
		AND bm.winlostdate <= @MoveBetsDay AND bm.winlostdate >= @BalanceUpDay 	
	GROUP BY bm.refno

	-- bettransm
	INSERT INTO #tmpMuayThai ( refno, NoOfMuayThai, IsBettran )
	SELECT bm.refno, COUNT (bm.transid) AS NoOfMuayThai, 1
	FROM #tmpbettrans b 
		INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON bm.refno = b.refno		
	WHERE bm.oddsspread = 44 AND bm.statusID NOT IN (101, 102, 103)
		AND bm.winlostdate > @MoveBetsDay
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
			AND m.eventdate >= DATEADD(DAY, -14, @WinlostDate) AND m.eventdate < @BalanceUpDay

		IF EXISTS (SELECT 1 FROM #MatchBK)
		BEGIN					
			INSERT INTO #tmpBK ( refno, transID, matchID, oddsspread )		
			SELECT bm.refno, bm.transid, bm.matchid, bm.oddsspread
			FROM DBARC.bodb_Archive.dbo.bettransm bm WITH (NOLOCK)
				INNER JOIN #bettransmBK b ON bm.refno = b.refno
			WHERE bm.winlostdate >= DATEADD(DAY, -14, @WinlostDate) 
				AND bm.winlostdate < @BalanceUpDay
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
			AND bm.winlostdate > @MoveBetsDay 
		GROUP BY bm.refno

		INSERT INTO #tmpSubParlay( refno, NoOfSubParlay )	
		SELECT bm.refno, COUNT(bm.transid)
		FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
		WHERE bm.statusID NOT IN (101, 102, 103)
			AND EXISTS (SELECT 1 FROM #tmpMuayThai t WHERE bm.refno = t.refno)
			AND bm.winlostdate <= @MoveBetsDay AND bm.winlostdate >= @BalanceUpDay 	 
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

	INSERT INTO #Source(SiteID, CurrencyId, StatusId, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL,
						Turnover, BetCount, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare, CustomerCategory, IsParlay)
	SELECT	
		ISNULL(siteT.SiteID,-1) AS SiteID			
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
					) 
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate = @WinlostDate 
			) b
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid AND c.roleid = 2
		LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON c.site = ibcsite.site
		LEFT JOIN bodb_Licensee.dbo.view_site_list siteT WITH (NOLOCK) ON ibcsite.siteid = siteT.IbcSiteID
	GROUP BY ISNULL(siteT.SiteID,-1), b.currency, b.statusid, b.customercategory, ibcsite.isDeposit
			, b.IsParlay
	DROP TABLE #tmpbettrans
	DROP TABLE #tmpMuayThai
	DROP TABLE #tmpSubParlay

	SET @S_Count = @@ROWCOUNT;

	-- Target
	INSERT INTO #Target(SiteID, CurrencyId, StatusId, CustomerCategory, IsParlay, LicenseeWL, AdjustedLicenseeWL, CustomerWL, AdjustedCustomerWL,
						Turnover, BetCount, CommissionS, AdjustedCommissionS, CommShare, AdjustedCommShare)
	SELECT	SiteID, CurrencyId, StatusId, CustomerCategory, IsParlay,
			ISNULL(LicenseeWL, 0), ISNULL(AdjustedLicenseeWL, 0), 
			ISNULL(CustomerWL, 0), ISNULL(AdjustedCustomerWL, 0),
			ISNULL(Turnover, 0), ISNULL(BetCount, 0), 
			ISNULL(CommissionS, 0), ISNULL(AdjustedCommissionS, 0), 
			ISNULL(CommShare, 0), ISNULL(AdjustedCommShare, 0)
	FROM dbo.rpt_BettingBySport WITH(NOLOCK)
	WHERE rptDate = @WinlostDate;

	SET @T_Count = @@ROWCOUNT;		

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	INSERT INTO #Log(TableName, IsSource, IsParlay, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	'bettrans14', 1, IsParlay, CurrencyID, SUM(Turnover), SUM(CustomerWL), SUM(BetCount),
			(
				SELECT	SUM(LicenseeWL) AS LicWL, SUM(CommissionS) AS CommS, SUM(CommShare) AS CommShare,
						SUM(AdjustedLicenseeWL) AS ALicWL, SUM(AdjustedCustomerWL) AS AWL, SUM(AdjustedCommissionS) AS ACommS, SUM(AdjustedCommShare) AS ACommShare
				FROM #Source s1
				WHERE s1.CurrencyId = s.CurrencyId AND s1.IsParlay = s.IsParlay
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.SiteID = t.SiteID AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId AND s.LicenseeWL = t.LicenseeWL AND s.CustomerWL = t.CustomerWL 
			AND s.Turnover = t.Turnover AND s.BetCount = t.BetCount AND s.CommissionS = t.CommissionS AND s.CommShare = t.CommShare 
			AND s.AdjustedLicenseeWL = t.AdjustedLicenseeWL AND s.AdjustedCustomerWL = t.AdjustedCustomerWL
			AND s.AdjustedCommissionS = t.AdjustedCommissionS AND s.AdjustedCommShare = t.AdjustedCommShare
			AND s.CustomerCategory = t.CustomerCategory AND s.IsParlay = t.IsParlay)
	GROUP BY CurrencyId, IsParlay
	
	UNION ALL
	
	SELECT 'rpt_BettingBySport', 0, IsParlay, CurrencyID, SUM(Turnover), SUM(CustomerWL), SUM(BetCount),
			(
				SELECT	SUM(LicenseeWL) AS LicWL, SUM(CommissionS) AS CommS, SUM(CommShare) AS CommShare,
					    SUM(AdjustedLicenseeWL) AS ALicWL, SUM(AdjustedCustomerWL) AS AWL, SUM(AdjustedCommissionS) AS ACommS, SUM(AdjustedCommShare) AS ACommShare
				FROM #Target t1
				WHERE t1.CurrencyId = t.CurrencyId AND t1.IsParlay = t.IsParlay
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.SiteID = t.SiteID AND s.CurrencyId = t.CurrencyId AND s.StatusId = t.StatusId AND s.LicenseeWL = t.LicenseeWL
			AND s.CustomerWL = t.CustomerWL AND s.Turnover = t.Turnover AND s.BetCount = t.BetCount
			AND s.CommissionS = t.CommissionS AND s.CommShare = t.CommShare 
			AND s.AdjustedLicenseeWL = t.AdjustedLicenseeWL AND s.AdjustedCustomerWL = t.AdjustedCustomerWL
			AND s.AdjustedCommissionS = t.AdjustedCommissionS AND s.AdjustedCommShare = t.AdjustedCommShare
			AND s.CustomerCategory = t.CustomerCategory AND s.IsParlay = t.IsParlay)
	GROUP BY CurrencyId, IsParlay;

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 0
	BEGIN
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM #Log WHERE CurrencyId <> 20)
	BEGIN
		SET @HasDataMismatch = 1;
	END
	ELSE
	BEGIN
		SET @HasDataMismatch = 2;
	END

	SELECT @IsParlay = STUFF(
			(
				SELECT DISTINCT ', ' + CAST(IsParlay AS VARCHAR(5))
				FROM #Log
				FOR XML PATH('')
			), 1, 2, ''
		);

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptBettingBySport_CheckData', 
			TableName, 
			IsSource,
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log;

	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END