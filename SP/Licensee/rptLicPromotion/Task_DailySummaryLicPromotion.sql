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
	SELECT site.SiteID
		,cs.currency AS currencyID
		,cs.custid
	INTO #tempLicSuper
	FROM bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) 
	INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.site = site.SiteName
	WHERE cs.currency <> 20

	-- COLLECT Promo Programs
	;WITH CTE_PromoProgram AS (
		SELECT DISTINCT @SPR_ProductID AS ProductID
			, StartDate, EndDate
			, OffPeakStartTime, OffPeakEndTime
		FROM @rptPromotion rpt
		WHERE ISNULL(CouponCount, 0) > 0 -- Valid Promo Program
	),
	-- COLLECT Promo Coupons
	CTE_PromoCoupon AS (
		SELECT [site].SiteID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			,rpt.CurrencyID
			,SUM(CouponCount) AS CouponCount
			,SUM(RedemptionCount) AS RedemptionCount
			,SUM(RedemptionPrize) AS RedemptionPrize
		FROM @rptPromotion rpt
		INNER JOIN bodb02.dbo.CustInfo ci WITH(NOLOCK) ON rpt.CustID = ci.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.CustId = ci.srecommend
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.site = site.SiteName
		GROUP BY [site].SiteID
			,rpt.CouponDate
			,rpt.CouponDateGMT
			,rpt.CurrencyID
	),
	-- COLLECT BET Tickets vs PromoTime
	CTE_PromoBet AS (
		SELECT
			-------------------Dimensions-------------
			lic.SiteID
			,lic.CurrencyID
			,promo.ProductID
			,bet.PromoDate
			,bet.TimeZone
			,bet.RptDateGMT
			-------------------Measures-------------
			,SUM(ISNULL(promoTime.IsPromoBet,0)) AS BetCountOfPromoTime
			,SUM(ISNULL(promoTime.IsPromoBet,0) * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
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
			-- peak out the Promo Program -- require
			CROSS APPLY (
				SELECT TOP(1) ProductID
				FROM CTE_PromoProgram program
				WHERE bet.PromoDate BETWEEN program.StartDate AND program.EndDate
			) AS promo 
			-- peak out the Promo Time - optional
			OUTER APPLY (
				SELECT TOP(1) 1 AS IsPromoBet
				FROM CTE_PromoProgram program
				WHERE bet.PromoDate BETWEEN program.StartDate AND program.EndDate
					AND (
						bet.TransHour >= program.OffPeakStartTime	-- after hh:00
						AND bet.TransHour < program.OffPeakEndTime	-- before hh:00
					)
			) AS promoTime 
		WHERE 
			b.transdate >= @startTransdate AND b.transdate < @endTransdate

		GROUP BY 
			lic.SiteID
			,lic.CurrencyID
			,promo.ProductID
			,bet.PromoDate
			,bet.TimeZone
			,bet.RptDateGMT
	),
	-- Promo Coupons vs Tickets Mapping
	source_rptLicPromotion AS (
		SELECT bet.SiteID,bet.CurrencyID,bet.PromoDate,bet.TimeZone,bet.RptDateGMT,bet.ProductId
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
			AND bet.PromoDate	= coupon.CouponDate
			AND bet.RptDateGMT	= coupon.CouponDateGMT
	)
	---- INSERT/UPDATE/DELETE from SOURCE
	MERGE dbo.rptLicPromotion		AS tgr --TARGET
	USING source_rptLicPromotion	AS src --SOURCE
	ON tgr.RptDate		= src.PromoDate
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
END
GO
