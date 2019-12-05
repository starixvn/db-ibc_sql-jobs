/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion]
	@Winlostdate	DATE,
	@timeZone		INT = 8
AS
/*
	Created: 20191203@Bobby
	Task: Summarize Promotion data into rptLicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion] '20191119'
*/
BEGIN
	DECLARE @SPR_ProductID	INT = 37
		,@startTransdate	DATETIME
		,@endTransdate		DATETIME
		,@today				DATE
	
	-- Supported currency
	DECLARE @tempLicCurrency TABLE
	(
		CurrencyID INT PRIMARY KEY
	)

	-- Promo Program
	DECLARE @promoProgram TABLE 
	(
		ProductID INT
		, StartDate DATE
		, EndDate	DATE
		, OffPeakStartTime TINYINT
		, OffPeakEndTime TINYINT
	)

	-- Promo - Coupon Summary
	CREATE TABLE #rptPromotion
	(
		CustID int PRIMARY KEY,
		PromoID	int,
		StartDate date,
		EndDate date,
		OffPeakStartTime tinyint,
		OffPeakEndTime tinyint,
		CurrencyID	int,
		CouponDate date,
		CouponTimeZone int,
		CouponDateGMT date,
		CouponCount int,
		RedemptionCount int,
		RedemptionPrize money
	)

	-- LIC supper with supported currency
	CREATE TABLE #tempLicSuper
	(
		CustID INT PRIMARY KEY,
		SiteName VARCHAR(30),
		CurrencyID INT,
		StatusID INT DEFAULT(0)
	)

	-- Bet & Promo program
	CREATE TABLE #rptLicPromotionBet (
		[CustID] [int] NOT NULL,
		[ProductID] [int] NOT NULL,
		[PromoDate] [date] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		[BetCount] [int] NULL,
		[BetCount_WonLose] [int] NULL,
		[Turnover] [money] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime] [int] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL
	)
	CREATE CLUSTERED INDEX CIX_rptLicPromotionBet ON #rptLicPromotionBet(CustID)

	-- REMOTE-QUERY: Promo Summary via MySQL
	BEGIN TRY
		DECLARE @RemoteSQL VARCHAR(1000), @currencyIds VARCHAR(100)

		-- GET: Cust with Coupon data
		INSERT INTO #rptPromotion(PromoID,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CustID,CurrencyID,CouponDate,CouponTimeZone,CouponDateGMT,CouponCount,RedemptionCount,RedemptionPrize)
		EXEC ('CALL Promotion.Intg_LA_GetPromoSummary(''' + @Winlostdate + ''');') at DBPROMO

		-- GET: Promo currency setting
		;WITH CTE_PromoProgram AS (	
			SELECT DISTINCT PromoID
			FROM #rptPromotion
		)
		SELECT @currencyIds = COALESCE(@currencyIds + ',', '') + CAST(PromoID AS VARCHAR(10))
		FROM CTE_PromoProgram

		SELECT @RemoteSQL = 'SELECT CurrencyID FROM OPENQUERY(DBPROMO,''SELECT DISTINCT CurrencyID FROM Promotion.NPHPromoCurrSetting WHERE PromoID IN('+@currencyIds+');'')'
		INSERT INTO @tempLicCurrency
		EXEC (@RemoteSQL)

	END TRY
	BEGIN CATCH 
		RETURN
	END CATCH

	-- NO Promo Program with Currency
	IF NOT EXISTS(SELECT 1 FROM @tempLicCurrency)
		RETURN

	-- SET start & end transaction date
	SELECT @startTransdate	= @Winlostdate
		, @endTransdate		= DATEADD(DD, 1, CAST(@Winlostdate AS DATETIME))
		, @today			= GETDATE()

	-- COLLEST Licensee SUPER vs Site
	INSERT INTO #tempLicSuper(SiteName, currencyID, custid)
	SELECT cs.[site] AS SiteName
		,cs.currency
		,cs.custid
	FROM bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
	INNER JOIN @tempLicCurrency cur ON cs.currency = cur.CurrencyID
	--WHERE cs.currency <> 20

	INSERT INTO @promoProgram(ProductID, StartDate, EndDate, OffPeakStartTime, OffPeakEndTime)
	SELECT 
		DISTINCT @SPR_ProductID AS ProductID
		, StartDate, EndDate
		, OffPeakStartTime, OffPeakEndTime
	FROM #rptPromotion rpt
	WHERE ISNULL(CouponCount, 0) > 0 -- Valid Promo Program

	-- COLLECT BET Tickets vs PromoTime
	INSERT INTO #rptLicPromotionBet(
		CustID,ProductID,PromoDate,TimeZone,RptDateGMT
		,BetCountOfPromoTime,BetCountOfPromoTime_WonLose,BetCount,BetCount_WonLose,Turnover,Turnover_WonLose
	)
	SELECT
		-------------------Dimensions-------------
		b.srecommend
		,promo.ProductID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT
		-------------------Measures-------------
		,SUM(promo.IsPromoBet) AS BetCountOfPromoTime
		,SUM(promo.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
		,COUNT(1) AS BetCount
		,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
		,SUM(b.stake) AS Turnover
		,SUM(b.stake * bet.IsWonLoseBet) AS Turnover_WonLose
	
	FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
	INNER JOIN #tempLicSuper lic ON b.srecommend = lic.custid
	INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
	CROSS APPLY (
		SELECT 
			CASE WHEN b.statusID IN (112, 113) THEN 1 ELSE 0 END IsWonLoseBet
			, CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) AS RptDateGMT
			, @timeZone AS TimeZone
			, DATEPART(HOUR, b.transdate) AS TransHour
			, CAST(b.transdate AS DATE) AS PromoDate
	) AS bet
	-- peak out the Promo Time
	CROSS APPLY (
		SELECT TOP(1) program.ProductID
			,CASE 
				WHEN (
						bet.TransHour >= program.OffPeakStartTime	-- after hh:00
						AND bet.TransHour < program.OffPeakEndTime	-- before hh:00 
					) THEN 1 
				ELSE 0 END AS IsPromoBet
		FROM @promoProgram program
		WHERE bet.PromoDate BETWEEN program.StartDate AND program.EndDate
		ORDER BY program.ProductID
			,IsPromoBet DESC
	) AS promo
	WHERE 
		b.winlostdate >= @winlostdate AND b.winlostdate <= @today
		AND (
			b.transdate >= @startTransdate 
			AND b.transdate < @endTransdate
		)

	GROUP BY 
		b.srecommend
		,promo.ProductID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT

	;WITH
	-- COLLECT Promo Coupons
	CTE_PromoCoupon AS (
		SELECT cs.[site] AS SiteName
			,rpt.CouponDate
			,rpt.CouponDateGMT
			,rpt.CurrencyID
			,SUM(CouponCount) AS CouponCount
			,SUM(RedemptionCount) AS RedemptionCount
			,SUM(RedemptionPrize) AS RedemptionPrize
		FROM #rptPromotion rpt
		INNER JOIN bodb02.dbo.CustInfo ci WITH(NOLOCK) ON rpt.CustID = ci.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.CustId = ci.srecommend
		GROUP BY cs.[site]
			,rpt.CurrencyID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			
	),
	-- Promo Coupons vs Tickets Mapping
	source_rptLicPromotion AS (
		SELECT [site].SiteID,lic.CurrencyID,bet.PromoDate,bet.TimeZone,bet.RptDateGMT, bet.ProductID
			,bet.BetCount
			,bet.BetCount_WonLose
			,bet.BetCountOfPromoTime
			,bet.BetCountOfPromoTime_WonLose
			,bet.Turnover
			,bet.Turnover_WonLose
			,ISNULL(coupon.CouponCount, 0) AS CouponCount
			,ISNULL(coupon.RedemptionCount, 0) AS RedemptionCount
			,ISNULL(coupon.RedemptionPrize, 0) AS RedemptionPrize
		FROM #rptLicPromotionBet bet
		INNER JOIN #tempLicSuper lic ON bet.CustID = lic.CustID
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON lic.SiteName = [site].SiteName
		LEFT JOIN CTE_PromoCoupon AS coupon 
			ON lic.SiteName		= coupon.SiteName
			AND lic.CurrencyID	= coupon.CurrencyID
			AND bet.PromoDate	= coupon.CouponDate
			AND bet.RptDateGMT	= coupon.CouponDateGMT
	)
	---- INSERT/UPDATE/DELETE from SOURCE
	MERGE dbo.rptLicPromotion		AS tgr --TARGET
	USING source_rptLicPromotion	AS src --SOURCE
	ON tgr.SiteID		=	 src.SiteID
		AND tgr.CurrencyID	= src.CurrencyID
		AND tgr.RptDate		= src.PromoDate
		AND tgr.TimeZone	= src.TimeZone
		AND tgr.RptDateGMT	= src.RptDateGMT
		AND tgr.ProductId	= src.ProductId
	WHEN MATCHED THEN
	UPDATE
		SET BetCount			= src.BetCount
		,BetCount_WonLose		= src.BetCount_WonLose
		,BetCountOfPromoTime	= src.BetCountOfPromoTime
		,BetCountOfPromoTime_WonLose	= src.BetCountOfPromoTime_WonLose
		,Turnover				= src.Turnover
		,Turnover_WonLose		= src.Turnover_WonLose
		,CouponCount			= ISNULL(src.CouponCount,0)
		,RedemptionCount		= ISNULL(src.RedemptionCount,0)
		,RedemptionPrize		= ISNULL(src.RedemptionPrize,0)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (RptDate,TimeZone,RptDateGMT,SiteID,CurrencyID,ProductID
			,BetCount
			,BetCount_WonLose
			,BetCountOfPromoTime
			,BetCountOfPromoTime_WonLose
			,Turnover
			,Turnover_WonLose
			,CouponCount
			,RedemptionCount
			,RedemptionPrize
		)
		VALUES(
			src.PromoDate,src.TimeZone,src.RptDateGMT,src.SiteID,src.CurrencyID,src.ProductID
			,src.BetCount
			,src.BetCount_WonLose
			,src.BetCountOfPromoTime
			,src.BetCountOfPromoTime_WonLose
			,src.Turnover
			,src.Turnover_WonLose
			,src.CouponCount
			,src.RedemptionCount
			,src.RedemptionPrize
		)
	WHEN NOT MATCHED BY SOURCE AND tgr.RptDate = @Winlostdate THEN
		DELETE
	;
	
	--- CLEANUP
	DROP TABLE #tempLicSuper
	DROP TABLE #rptPromotion
	DROP TABLE #rptLicPromotionBet
END
GO
