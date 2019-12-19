/*
	Created: 20191213@Bobby
	Task: Summarize Promotion data into rptLicPromotion for bettrans14
	DB: DBLIC.bodb_LicenseeReport - [RedmineID #125358]
*/
use bodb_LicenseeReport
go
BEGIN
	DECLARE
		@PromoDate			DATE = '20191213',
		@Timezone			INT = 8,
		@Error				INT = 0,
		@Message			VARCHAR(200) = ''

	DECLARE @SPR_ProductID	INT = 37
		,@startTransdate	DATETIME
		,@endTransdate		DATETIME
		,@today				DATE
		,@yesterday			DATE
		,@BalanceUpDate		DATE
		,@MovebetDate		DATE
		,@CutoffDate		DATE
		,@_PromoDate		DATE
	
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	-- Supported currency
	DECLARE @tempLicCurrency TABLE
	(
		CurrencyID INT PRIMARY KEY
	)

	-- Promo Program
	DECLARE @promoSetting TABLE 
	(
		PromoID				INT
		, StartDate			DATE
		, EndDate			DATE
		, OffPeakStartTime	TINYINT
		, OffPeakEndTime	TINYINT
		, CurrencyID		TINYINT
		, CouponCount		INT
	)

	DECLARE @promoProgram TABLE 
	(
		ProductID			INT
		, PromoID			INT
		, StartDate			DATE
		, EndDate			DATE
		, OffPeakStartTime	TINYINT
		, OffPeakEndTime	TINYINT
	)

	-- Promo - Coupon Summary
	CREATE TABLE #rptLicPromoCoupon
	(
		CustID int,
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
	CREATE CLUSTERED INDEX CIX_rptLicPromoCoupon ON #rptLicPromoCoupon(CustID)

	-- LIC supper with supported currency
	CREATE TABLE #tempLicSuper
	(
		CustID INT PRIMARY KEY,
		SiteName VARCHAR(30),
		CurrencyID INT,
		StatusID INT DEFAULT(0)
	)

	-- Bet & Promo program
	CREATE TABLE #rptLicPromoBet (
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
		[BetCountOfPromoTime_WonLose] [int] NULL,
		[PromoInfo] [varchar](100) NULL
	)
	CREATE CLUSTERED INDEX CIX_rptLicPromotionBet ON #rptLicPromoBet(CustID)

	-- rptLicPromotion Soure
	CREATE TABLE #source_rptLicPromotion (
		[RptDate] [date] NOT NULL,
		[SiteID] [int] NOT NULL,
		[CurrencyID] [int] NOT NULL,
		[ProductID] [int] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		[BetCount] [int] NULL,
		[BetCount_WonLose] [int] NULL,
		[Turnover] [money] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime] [int] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL,
		[CouponCount] [int] NULL,
		[RedemptionCount] [int] NULL,
		[RedemptionPrize] [money] NULL,
		CONSTRAINT PK_source_rptLicPromotion PRIMARY KEY CLUSTERED 
		(
			[RptDate] ASC
			, [SiteID] ASC
			, [CurrencyID] ASC
			, [ProductID] ASC
			, [TimeZone] ASC
			, [RptDateGMT] ASC
		)
	)
	-- GET BU & MB Dates
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @BalanceUpDate	= BalanceUpDay
		,@MovebetDate		= MoveBetDay
	FROM @BalanceUpDays

	-- INIT: dates
	SELECT @Message			= '' 
		, @today			= GETDATE() 
		, @yesterday		= DATEADD(DD, -1, CAST(@today AS DATETIME))
		, @PromoDate		= ISNULL(@PromoDate, @yesterday) 
		, @CutoffDate		= '20191213'
		
	-- CORRECT: PromoDate - Start & End Program transdate
	SELECT @_PromoDate		= CASE 
								WHEN @PromoDate > @yesterday THEN @yesterday
								ELSE @PromoDate
							END
		, @startTransdate	= @_PromoDate
		, @endTransdate		= DATEADD(DD, 1, CAST(@_PromoDate AS DATETIME)) 

	-- CHECK CUT-OFF DAY
	IF (@_PromoDate < @CutoffDate)
	BEGIN
		SELECT @Message = 'Invalid promo date ' + CAST(@_PromoDate AS VARCHAR(10)) + ' is lower than cut-off day ' + CAST(@CutoffDate AS VARCHAR(10))
		GOTO CLEANUP
	END

	-- REMOTE-QUERY: Promo Summary via MySQL
	BEGIN TRY
		--Promotion Setting
		INSERT INTO @promoSetting(PromoId,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CurrencyID,CouponCount)
		EXEC ('CALL Promotion.Intg_LA_GetPromoSettingByDate(''' + @_PromoDate + ''');') at DBPROMO

		INSERT INTO @promoProgram(ProductID, PromoId, StartDate,EndDate,OffPeakStartTime,OffPeakEndTime)
		SELECT DISTINCT @SPR_ProductID AS ProductID
			,PromoId,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime
		FROM @promoSetting
		WHERE ISNULL(CouponCount,0) > 0 -- Valid Promo Program

		INSERT INTO @tempLicCurrency(CurrencyID)
		SELECT DISTINCT CurrencyID
		FROM @promoSetting

		-- GET: Cust Coupon with PromoDate
		INSERT INTO #rptLicPromoCoupon(PromoID,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CustID,CurrencyID,CouponDate,CouponTimeZone,CouponDateGMT,CouponCount,RedemptionCount,RedemptionPrize)
		EXEC ('CALL Promotion.Intg_LA_GetPromoSummary(''' + @_PromoDate + ''');') at DBPROMO

		DELETE #rptLicPromoCoupon
		WHERE CustID IS NULL
	END TRY
	BEGIN CATCH
		SELECT @Error = 101 
			,@Message = ERROR_MESSAGE()
		GOTO CLEANUP
	END CATCH

	-- NO Promo Program with Currency
	IF NOT EXISTS(SELECT 1 FROM @tempLicCurrency)
	OR NOT EXISTS(SELECT 1 FROM #rptLicPromoCoupon)
	BEGIN
		SELECT @Message = 'NO Promo Program found'
		GOTO CLEANUP
	END

	-- COLLEST Licensee SUPER vs Site
	INSERT INTO #tempLicSuper(SiteName, currencyID, custid)
	SELECT cs.[site] AS SiteName
		,cs.currency
		,cs.custid
	FROM bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
	--INNER JOIN @tempLicCurrency cur ON cs.currency = cur.CurrencyID
	WHERE cs.currency <> 20

	-- COLLECT BET Tickets vs PromoTime
	INSERT INTO #rptLicPromoBet(
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
	
	FROM bodb02.dbo.bettrans14 b WITH(NOLOCK) 
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
		ORDER BY IsPromoBet DESC
	) AS promo
	WHERE 
		b.winlostdate >= @_PromoDate -- COVER cross day between transdate vs winlostdate

	GROUP BY 
		b.srecommend
		,promo.ProductID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT

	-- REMOVE unexpected PromoDate
	DELETE FROM #rptLicPromoBet
	WHERE PromoDate <> @_PromoDate

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
		FROM #rptLicPromoCoupon rpt
		INNER JOIN bodb02.dbo.CustInfo ci WITH(NOLOCK) ON rpt.CustID = ci.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.CustId = ci.srecommend
		GROUP BY cs.[site]
			,rpt.CurrencyID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			
	)
	-- Promo Coupons vs Tickets Mapping
	INSERT INTO #source_rptLicPromotion (RptDate,SiteID,CurrencyID,TimeZone,RptDateGMT,ProductID
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
	SELECT bet.PromoDate,[site].SiteID,lic.CurrencyID,bet.TimeZone,bet.RptDateGMT, bet.ProductID
		,SUM(bet.BetCount) AS BetCount
		,SUM(bet.BetCount_WonLose) AS BetCount_WonLose
		,SUM(bet.BetCountOfPromoTime) AS BetCountOfPromoTime
		,SUM(bet.BetCountOfPromoTime_WonLose) AS BetCountOfPromoTime_WonLose
		,SUM(bet.Turnover) AS Turnover
		,SUM(bet.Turnover_WonLose) AS Turnover_WonLose
		,SUM(ISNULL(coupon.CouponCount, 0)) AS CouponCount
		,SUM(ISNULL(coupon.RedemptionCount, 0)) AS RedemptionCount
		,SUM(ISNULL(coupon.RedemptionPrize, 0)) AS RedemptionPrize
	FROM #rptLicPromoBet bet
	INNER JOIN #tempLicSuper lic ON bet.CustID = lic.CustID
	INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON lic.SiteName = site.SiteName
	LEFT JOIN CTE_PromoCoupon AS coupon 
		ON lic.SiteName		= coupon.SiteName
		AND lic.CurrencyID	= coupon.CurrencyID
		AND bet.PromoDate	= coupon.CouponDate
		AND bet.RptDateGMT	= coupon.CouponDateGMT
	GROUP BY [site].SiteID,lic.CurrencyID,bet.PromoDate,bet.TimeZone,bet.RptDateGMT, bet.ProductID

	IF (EXISTS(SELECT 1 FROM #source_rptLicPromotion))
	BEGIN
		---- INSERT/UPDATE/DELETE from SOURCE
		MERGE dbo.rptLicPromotion				AS tgr --TARGET
		USING #source_rptLicPromotion	AS src --SOURCE
		ON tgr.RptDate			= src.RptDate
			AND tgr.SiteID		= src.SiteID
			AND tgr.CurrencyID	= src.CurrencyID
			AND tgr.TimeZone	= src.TimeZone
			AND tgr.RptDateGMT	= src.RptDateGMT
			AND tgr.ProductId	= src.ProductId
		WHEN MATCHED AND tgr.RptDate = @_PromoDate THEN
		UPDATE
			SET BetCount			= src.BetCount
			,BetCount_WonLose		= src.BetCount_WonLose
			,BetCountOfPromoTime	= src.BetCountOfPromoTime
			,BetCountOfPromoTime_WonLose	= src.BetCountOfPromoTime_WonLose
			,Turnover				= src.Turnover
			,Turnover_WonLose		= src.Turnover_WonLose
			,CouponCount			= src.CouponCount
			,RedemptionCount		= src.RedemptionCount
			,RedemptionPrize		= src.RedemptionPrize
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (RptDate,SiteID,CurrencyID,TimeZone,RptDateGMT,ProductID
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
				src.RptDate,src.SiteID,src.CurrencyID,src.TimeZone,src.RptDateGMT,src.ProductID
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
		WHEN NOT MATCHED BY SOURCE AND tgr.RptDate = @_PromoDate THEN
			DELETE
		;
	END

	--- CLEANUP
	CLEANUP:
		SELECT @Message AS [@Message]
		DROP TABLE #tempLicSuper
		DROP TABLE #rptLicPromoCoupon
		DROP TABLE #source_rptLicPromotion
		DROP TABLE #rptLicPromoBet
END
GO