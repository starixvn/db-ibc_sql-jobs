/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion_CheckData]
	@TimeZone			INT = 8,
	@IsCheckDataOnly	BIT = 1,
	@Error				INT = 0, --OUTPUT,
	@Message			VARCHAR(200) = '' --OUTPUT
AS
/*
	Created: 20191203@Bobby
	Task: Summarize Promotion data into rptLicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:
		- @PromoDate: DATE - Is the promotion date that needs to generate summary data
			+ It should be the yesterday

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion] '20191119'
*/
BEGIN
	DECLARE @SPR_ProductID	INT = 37
		,@startTransdate	DATETIME
		,@endTransdate		DATETIME
		,@today				DATE
		,@yesterday			DATE
		,@BalanceUpDate		DATE
		,@MovebetDate		DATE
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
		[PromoID] [int] NOT NULL,
		[PromoDate] [date] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		--------------------------------
		[BetCount_WonLose] [int] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL
	)
	CREATE CLUSTERED INDEX CIX_rptLicPromotionBet ON #rptLicPromoBet(CustID)

	-- rptLicPromotion Correct
	CREATE TABLE #source_rptLicPromotion_Correct (
		[PromoDate] [date] NOT NULL,
		[SiteID] [int] NOT NULL,
		[CurrencyID] [int] NOT NULL,
		[ProductID] [int] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		-----------------------------
		[BetCount_WonLose] [int] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL,
		[Turnover_WonLose] [money] NULL,
		CONSTRAINT PK_source_rptLicPromotion_Correct PRIMARY KEY CLUSTERED 
		(
			[PromoDate] ASC
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
	SELECT @Error			= 0 
		, @Message			= '' 
		, @today			= GETDATE() 
		, @yesterday		= DATEADD(DD, -1, CAST(@today AS DATETIME))
		, @startTransdate	= @BalanceupDate
		, @endTransdate		= DATEADD(DD, 1, CAST(@MovebetDate AS DATETIME))


	-- REMOTE-QUERY: Promo Summary via MySQL
	BEGIN TRY
		DECLARE @RemoteSQL VARCHAR(1000), @RemoteDate DATE

		SET @RemoteDate = CAST(@startTransdate AS DATE)
		-- GET: Promo setting
		SELECT @RemoteSQL = '\
			SELECT PromoId,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CurrencyID,CouponCount
			FROM OPENQUERY(DBPROMO,''SELECT p.PromoId,p.StartDate,p.EndDate,p.OffPeakStartTime,p.OffPeakEndTime,cs.CurrencyID,COUNT(1) AS CouponCount
									FROM Promotion.NPHPromotion p
									INNER JOIN Promotion.NPHPromoCurrSetting cs ON cs.PromoID = p.PromoId
									LEFT JOIN Promotion.NPHPromoCoupon pc ON cs.PromoID = p.PromoId AND cs.CurrencyID = pc.CurrencyID
									WHERE p.StartDate >= '''''+ CAST(@RemoteDate AS VARCHAR(10)) +''''' OR '''''+ CAST(@RemoteDate AS VARCHAR(10)) +''''' BETWEEN p.StartDate AND p.EndDate
									GROUP BY p.PromoId,p.StartDate,p.EndDate,p.OffPeakStartTime,p.OffPeakEndTime,cs.CurrencyID;''
							)'
		--SELECT @RemoteSQL

		INSERT INTO @promoSetting(PromoId,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CurrencyID,CouponCount)
		EXEC (@RemoteSQL)

		INSERT INTO @promoProgram(ProductID, PromoId, StartDate,EndDate,OffPeakStartTime,OffPeakEndTime)
		SELECT DISTINCT @SPR_ProductID AS ProductID
			,PromoId,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime
		FROM @promoSetting
		WHERE ISNULL(CouponCount,0) > 0 -- Valid Promo Program

		INSERT INTO @tempLicCurrency(CurrencyID)
		SELECT DISTINCT CurrencyID
		FROM @promoSetting

	END TRY
	BEGIN CATCH
		SELECT @Error = 101
			, @Message = ERROR_MESSAGE()
		GOTO CLEANUP
	END CATCH

	-- NO Promo Program with Currency
	IF NOT EXISTS(SELECT 1 FROM @tempLicCurrency)
	BEGIN
		SELECT @Message = 'NO Promo Program'
		GOTO CLEANUP
	END

	-- COLLEST Licensee SUPER vs Site
	INSERT INTO #tempLicSuper(SiteName, currencyID, custid)
	SELECT cs.[site] AS SiteName
		,cs.currency
		,cs.custid
	FROM bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK)
	INNER JOIN @tempLicCurrency cur ON cs.currency = cur.CurrencyID
	--WHERE cs.currency <> 20

	-- COLLECT BET Tickets vs PromoTime
	INSERT INTO #rptLicPromoBet(
		CustID,ProductID,PromoID,PromoDate,TimeZone,RptDateGMT
		,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
	)
	SELECT
		-------------------Dimensions-------------
		b.srecommend AS CustID
		,promo.ProductID
		,promo.PromoID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT
		-------------------Measures-------------
		,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
		,SUM(b.stake * bet.IsWonLoseBet) AS Turnover_WonLose
		,SUM(promo.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
	
	FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
	INNER JOIN #tempLicSuper lic ON b.srecommend = lic.custid
	INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
	CROSS APPLY (
		SELECT 1 IsWonLoseBet
			, CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) AS RptDateGMT
			, @timeZone AS TimeZone
			, DATEPART(HOUR, b.transdate) AS TransHour
			, CAST(b.transdate AS DATE) AS PromoDate
	) AS bet
	-- peak out the Promo Time
	CROSS APPLY (
		SELECT TOP(1) program.ProductID, program.PromoID
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
		b.winlostdate > @MovebetDate AND b.winlostdate <= @today -- COVER cross day between transdate vs winlostdate
		AND b.statusID IN (112, 113)
		AND (
			b.transdate >= @startTransdate 
			AND b.transdate < @endTransdate
		)

	GROUP BY 
		b.srecommend
		,promo.ProductID
		,promo.PromoID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT
	
	--SELECT distinct PromoDate FROM #rptLicPromoBet

	--SELECT DISTINCT bet.PromoDate, bet.RptDateGMT FROM #rptLicPromoBet bet
	--- CHECK & CORRECT upto BU date
	IF EXISTS(SELECT 1 FROM #rptLicPromoBet bet WHERE PromoDate <= @MovebetDate)
	BEGIN
		
		WITH CTE_ChangedSuper AS
		(
			SELECT DISTINCT CustID, PromoDate
			FROM #rptLicPromoBet
		),
		CTE_PromoBet14 AS (
			SELECT 
				b.srecommend AS custId
				,promo.ProductID
				,promo.PromoID
				,bet.PromoDate
				,bet.TimeZone
				,bet.RptDateGMT
				,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
				,SUM(b.stake) AS Turnover_WonLose 
				,SUM(promo.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
			INNER JOIN CTE_ChangedSuper cs ON b.srecommend = cs.CustID AND b.winlostdate = cs.PromoDate
			INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
			CROSS APPLY (
				SELECT 1 AS IsWonLoseBet 
					, CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) AS RptDateGMT
					, @timeZone AS TimeZone
					, DATEPART(HOUR, b.transdate) AS TransHour
					, b.winlostdate AS PromoDate
			) AS bet
			-- peak out the Promo Time
			CROSS APPLY (
				SELECT TOP(1) program.ProductID, program.PromoID
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
			WHERE b.statusID IN (112,113)
				--AND EXISTS(SELECT 1 FROM #rptLicPromoBet tmp WHERE b.srecommend = tmp.CustID AND b.winlostdate = tmp.PromoDate)
				
			GROUP BY 
				b.srecommend
				,promo.ProductID
				,promo.PromoID
				,bet.PromoDate
				,bet.TimeZone
				,bet.RptDateGMT
		)

		INSERT INTO #source_rptLicPromotion_Correct
		SELECT bet.PromoDate
			,[site].[SiteID]
			,lic.CurrencyID
			,bet.[ProductID]
			,bet.TimeZone
			,bet.RptDateGMT
			,SUM(bet.BetCount_WonLose)
			,SUM(bet.BetCountOfPromoTime_WonLose)
			,SUM(bet.Turnover_WonLose)
		FROM ( 
			
			SELECT CustID,ProductID,PromoID,PromoDate,TimeZone,RptDateGMT
				,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
			FROM #rptLicPromoBet bet

			UNION ALL
			SELECT CustID,ProductID,PromoID,PromoDate,TimeZone,RptDateGMT
				,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
			FROM CTE_PromoBet14
		) AS bet
		INNER JOIN #tempLicSuper lic ON bet.CustID = lic.CustID
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON lic.SiteName = site.SiteName
		GROUP BY
			bet.PromoDate
			,[site].[SiteID]
			,lic.CurrencyID
			,bet.[ProductID]
			,bet.TimeZone
			,bet.RptDateGMT

		IF (@IsCheckDataOnly = 1)
		BEGIN
			SELECT DISTINCT 'Promotion data changed on ' + CAST(PromoDate AS VARCHAR(10))
			FROM #source_rptLicPromotion_Correct

			--------------------------------------
			SELECT TOP(10) * 
			FROM #source_rptLicPromotion_Correct
		END
		ELSE
		BEGIN
			---- UPDATE from SOURCE
			MERGE dbo.rptLicPromotion				AS tgr --TARGET
			USING #source_rptLicPromotion_Correct	AS src --SOURCE
			ON tgr.RptDate			= src.PromoDate
				AND tgr.SiteID		= src.SiteID
				AND tgr.CurrencyID	= src.CurrencyID
				AND tgr.TimeZone	= src.TimeZone
				AND tgr.RptDateGMT	= src.RptDateGMT
				AND tgr.ProductId	= src.ProductId
			WHEN MATCHED AND tgr.BetCount_WonLose <> src.BetCount_WonLose THEN
			UPDATE
				SET BetCount_WonLose			= src.BetCount_WonLose
				,BetCountOfPromoTime_WonLose	= src.BetCountOfPromoTime_WonLose
				,Turnover_WonLose				= src.Turnover_WonLose
			;
		END
	END
	
	--- CLEANUP
	CLEANUP:
		SELECT @Message AS [Message]
		DROP TABLE #tempLicSuper
		DROP TABLE #source_rptLicPromotion_Correct
		DROP TABLE #rptLicPromoBet
END
GO
