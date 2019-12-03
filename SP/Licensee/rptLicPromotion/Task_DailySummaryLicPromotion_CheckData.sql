/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion_CheckData]
	@Winlostdate		DATE,
	@TimeZone			INT = 8,
	@IsCheckDataOnly	BIT = 0
AS

/*
	Created: 20191203@Bobby
	Task: Check and Correct Promotion data into rptLicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion_CheckData] '20191126', 8, 1
*/
BEGIN
	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME

	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	-- GET BU & MB Dates
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	IF @Winlostdate > @CurrentMB_Date 
		RETURN

	--- START: Process
	DECLARE @NonPeakHourPromoId INT = 37
		,@startTransdate		DATETIME
		,@endTransdate			DATETIME

	DECLARE  @rptPromotion TABLE (
		PromoID	int,
		StartDate date,
		EndDate date,
		OffPeakStartTime tinyint,
		OffPeakEndTime tinyint,
		CustID int,
		CurrencyID	int,
		CouponDate datetime,
		CouponTimeZone int,
		CouponDateGMT date,
		CouponCount int,
		RedemptionCount int,
		RedemptionPrize money)

	CREATE TABLE #rptLicPromotionBet (
		[RptDate] [date] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		[SiteID] [int] NOT NULL,
		[CurrencyID] [int] NOT NULL,
		[ProductID] [int] NOT NULL,
		[BetCount] [int] NULL,
		[BetCount_WonLose] [int] NULL,
		[Turnover] [money] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime] [int] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL
	)

	CREATE TABLE #source_RptLicPromotion (
		[RptDate] [date] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		[SiteID] [int] NOT NULL,
		[CurrencyID] [int] NOT NULL,
		[ProductID] [int] NOT NULL,
		[BetCount] [int] NULL,
		[BetCount_WonLose] [int] NULL,
		[Turnover] [money] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime] [int] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL,
		[CouponCount] [int] NULL,
		[RedemptionCount] [int] NULL,
		[RedemptionPrize] [money] NULL
	)

	BEGIN TRY
		INSERT INTO @rptPromotion(PromoID,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CustID,CurrencyID,CouponDate,CouponTimeZone,CouponDateGMT,CouponCount,RedemptionCount,RedemptionPrize)
		EXEC ('CALL Promotion.Intg_LA_GetPromoSummary(''' + @Winlostdate + ''');') at DBPROMO
	END TRY
	BEGIN CATCH 
		RETURN
	END CATCH

	-- NO Promo Program Found
	IF NOT EXISTS(SELECT 1 FROM @rptPromotion)
		RETURN

	-- SET start & end transaction date
	SELECT @startTransdate	= @Winlostdate
		, @endTransdate		= DATEADD(DD, 1, CAST(@Winlostdate AS DATETIME))

	-- COLLEST Licensee SUPER vs Site
	SELECT [site].[SiteID]
		, cs.currency AS currencyID
		, cs.custid
	INTO #tempLicSuper
	FROM bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) 
	INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.site = site.SiteName
	WHERE cs.currency <> 20

	-- COLLECT Promo Programs
	SELECT DISTINCT PromoID, @NonPeakHourPromoId AS ProductID
		, StartDate, EndDate
		, OffPeakStartTime, OffPeakEndTime
	INTO #promoProgram
	FROM @rptPromotion rpt

	-- COLLECT Promo Time Tickets - Bettrans
	INSERT INTO #rptLicPromotionBet(
		SiteID,CurrencyID,PromoID,ProductID,RptDate,TimeZone,RptDateGMT
		,BetCountOfPromoTime,BetCountOfPromoTime_WonLose,BetCount,BetCount_WonLose,Turnover,Turnover_WonLose
	)
	SELECT
		-------------------Dimensions-------------
		lic.SiteID
		,lic.CurrencyID
		,promo.ProductID
		,bet.RptDate
		,bet.TimeZone
		,bet.RptDateGMT
		-------------------Measures-------------
		,SUM(bet.IsPromoBet) AS BetCountOfPromoTime
		,SUM(bet.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
		,COUNT(1) AS BetCount
		,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
		,SUM(b.stake) AS Turnover
		,SUM(b.stake * bet.IsWonLoseBet) AS Turnover_WonLose
	
	FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
		INNER JOIN #tempLicSuper lic ON b.srecommend = lic.custid
		INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
		CROSS APPLY (
			SELECT PromoID, ProductID, StartDate, EndDate, OffPeakStartTime, OffPeakEndTime
			FROM #promoProgram program
			WHERE b.transdate >= program.StartDate 
				AND b.transdate <= DATEADD(DD, 1, program.EndDate)
		) AS promo -- peak out the Promo Program
		CROSS APPLY (
			SELECT 
				CASE WHEN DATEPART(HOUR, b.transdate) BETWEEN promo.OffPeakStartTime AND promo.OffPeakEndTime THEN 1 ELSE 0 END AS IsPromoBet
				, CASE WHEN b.statusID IN (112, 113) THEN 1 ELSE 0 END IsWonLoseBet
				, CAST(b.transdate AS DATE) RptDate
				, CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) AS RptDateGMT
				, @timeZone AS TimeZone
		) AS bet
	WHERE 
		b.transdate >= @startTransdate AND b.transdate < @endTransdate

	GROUP BY 
		lic.SiteID
		,lic.CurrencyID
		,promo.ProductID
		,bet.RptDate
		,bet.TimeZone
		,bet.RptDateGMT
	
	-- COLLECT Promo Time Tickets - Bettrans14
	INSERT INTO #rptLicPromotionBet(
		SiteID,CurrencyID,PromoID,ProductID,RptDate,TimeZone,RptDateGMT
		,BetCountOfPromoTime,BetCountOfPromoTime_WonLose,BetCount,BetCount_WonLose,Turnover,Turnover_WonLose
	)
	SELECT
		-------------------Dimensions-------------
		lic.SiteID
		,lic.CurrencyID
		,promo.PromoID
		,promo.ProductID
		,bet.RptDate
		,bet.TimeZone
		,bet.RptDateGMT
		-------------------Measures-------------
		,SUM(bet.IsPromoBet) AS BetCountOfPromoTime
		,SUM(bet.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
		,COUNT(1) AS BetCount
		,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
		,SUM(b.stake) AS Turnover
		,SUM(b.stake * bet.IsWonLoseBet) AS Turnover_WonLose
	
	FROM bodb02.dbo.bettrans14 b WITH(NOLOCK) 
		INNER JOIN #tempLicSuper lic ON b.srecommend = lic.custid
		INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
		CROSS APPLY (
			SELECT PromoID, ProductID, StartDate, EndDate, OffPeakStartTime, OffPeakEndTime
			FROM #promoProgram program
			WHERE b.transdate >= program.StartDate 
				AND b.transdate <= DATEADD(DD, 1, program.EndDate)
		) AS promo -- peak out the Promo Program
		CROSS APPLY (
			SELECT 
				CASE WHEN DATEPART(HOUR, b.transdate) BETWEEN promo.OffPeakStartTime AND promo.OffPeakEndTime THEN 1 ELSE 0 END AS IsPromoBet
				, CASE WHEN b.statusID IN (112, 113) THEN 1 ELSE 0 END IsWonLoseBet
				, CAST(b.transdate AS DATE) RptDate
				, CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) AS RptDateGMT
				, @timeZone AS TimeZone
		) AS bet
	WHERE 
		b.transdate >= @startTransdate AND b.transdate < @endTransdate

	GROUP BY 
		lic.SiteID
		,lic.CurrencyID
		,promo.PromoID
		,promo.ProductID
		,bet.RptDate
		,bet.TimeZone
		,bet.RptDateGMT

	--- MERGE bets
	;WITH CTE_PromoBet AS (
		SELECT 
			bet.SiteID
			,bet.CurrencyID
			,bet.PromoID
			,bet.ProductID
			,bet.RptDate
			,bet.TimeZone
			,bet.RptDateGMT
			,SUM(bet.BetCount) AS BetCount
			,SUM(bet.BetCount_WonLose) AS BetCount_WonLose
			,SUM(bet.BetCountOfPromoTime) AS BetCountOfPromoTime
			,SUM(bet.BetCountOfPromoTime_WonLose) AS BetCountOfPromoTime_WonLose
			,SUM(bet.Turnover) AS Turnover
			,SUM(bet.Turnover_WonLose) AS Turnover_WonLose

		FROM #rptLicPromotion bet
		GROUP BY 
			bet.SiteID
			,bet.CurrencyID
			,bet.PromoID
			,bet.ProductID
			,bet.RptDate
			,bet.TimeZone
			,bet.RptDateGMT
	),
	-- COLLECT Promo Coupons
	CTE_PromoCoupon AS (
		SELECT [site].SiteID
			,rpt.CurrencyID
			,rpt.PromoID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			,SUM(CouponCount) AS CouponCount
			,SUM(RedemptionCount) AS RedemptionCount
			,SUM(RedemptionPrize) AS RedemptionPrize
		FROM @rptPromotion rpt
		INNER JOIN bodb02.dbo.CustInfo ci WITH(NOLOCK) ON rpt.CustID = ci.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.CustId = ci.srecommend
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.site = site.SiteName
		GROUP BY cs.site
			,rpt.PromoID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			,rpt.CurrencyID
	)
	-- Promo Coupons vs Tickets Mapping
	--,source_rptLicPromotion AS (
	INSERT INTO #source_rptLicPromotion
		SELECT bet.SiteID, bet.CurrencyID, bet.RptDate, bet.TimeZone, bet.RptDateGMT, bet.PromoID, bet.RptDate,bet.ProductId
			,bet.BetCount
			,bet.BetCount_WonLose
			,bet.BetCountOfPromoTime
			,bet.BetCountOfPromoTime_WonLose
			,bet.Turnover
			,bet.Turnover_WonLose
			,ISNULL(coupon.CouponCount, 0) AS CouponCount
			,ISNULL(coupon.RedemptionCount, 0) AS RedemptionCount
			,ISNULL(coupon.RedemptionPrize, 0) AS RedemptionPrize
		FROM CTE_PromoBet bet
		LEFT JOIN CTE_PromoCoupon AS coupon 
			ON bet.SiteID		= coupon.SiteID
			AND bet.currencyID	= coupon.CurrencyID
			AND bet.PromoID		= coupon.PromoID
			AND bet.RptDate		= coupon.CouponDate
			AND bet.RptDateGMT	= coupon.CouponDateGMT
	--)
	IF EXISTS(
		SELECT 1
		FROM #source_rptLicPromotion AS src
		FULL OUTER JOIN (
			SELECT * 
			FROM dbo.rptLicPromotion WITH(NOLOCK)
			WHERE RptDate = @Winlostdate
		) AS tgr
		ON tgr.RptDate			= src.RptDate
			AND tgr.RptDateGMT	= src.RptDateGMT
			AND tgr.SiteID		= src.SiteID
			AND tgr.CurrencyID	= src.CurrencyID
			AND tgr.TimeZone	= src.TimeZone
			AND tgr.ProductId	= src.ProductId
			AND tgr.PromoID		= src.PromoID
		WHERE 
			tgr.RptDate IS NULL
			OR src.RptDate IS NULL
			OR (
				tgr.BetCount				<> src.BetCount
				OR tgr.BetCount_WonLose		<> src.BetCount_WonLose
				OR tgr.BetCountOfPromoTime	<> src.BetCountOfPromoTime
				OR tgr.BetCountOfPromoTime_WonLose	<> src.BetCountOfPromoTime_WonLose
				OR tgr.Turnover				<> src.Turnover
				OR tgr.Turnover_WonLose		<> src.Turnover_WonLose
				OR tgr.CouponCount			<> src.CouponCount
				OR tgr.RedemptionCount		<> src.RedemptionCount
				OR tgr.RedemptionPrize		<> src.RedemptionPrize
			)
	)
	BEGIN
		IF (@IsCheckDataOnly = 1)
		BEGIN
			--TODO: SHOW DIFF Promotion Data
			SELECT 'Wrong Promotion data on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			RETURN
		END

		-- @IsCheckDataOnly = 0
		-- INSERT/UPDATE/DELETE from SOURCE
		MERGE dbo.rptLicPromotion		AS tgr --TARGET
		USING #source_rptLicPromotion	AS src --SOURCE
		ON tgr.PromoID			= src.PromoID
			AND tgr.RptDate		= src.RptDate
			AND tgr.RptDateGMT	= src.RptDateGMT
			AND tgr.SiteID		= src.SiteID
			AND tgr.CurrencyID	= src.CurrencyID
			AND tgr.TimeZone	= src.TimeZone
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
			INSERT (PromoID,RptDate,TimeZone,RptDateGMT,SiteID,CurrencyID,ProductID
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
				src.PromoID,src.RptDate,src.TimeZone,src.RptDateGMT,src.SiteID,src.CurrencyID,src.ProductID
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
	END
	
	--- CLEANUP
	DROP TABLE #tempLicSuper
	DROP TABLE #source_rptLicPromotion
END
GO