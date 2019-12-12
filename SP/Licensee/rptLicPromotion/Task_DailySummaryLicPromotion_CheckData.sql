/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummaryLicPromotion_CheckData]
	@PromoDate			DATE = NULL,
	@TimeZone			INT = 8,
	@IsCheckDataOnly	BIT = 0,
	@Error				INT = 0 OUTPUT,
	@Message			VARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20191203@Bobby
	Task: Summarize Promotion data into rptLicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20191203@Bobby: Initialize [Redmine: #119538]

	Param's Explanation:
		- @TimeZone: INT - The GMT value that will be converted to
		- @IsCheckDataOnly: BIT - [0|1]
			+ 0: Check and correct data 
			+ 1: Check and show data

	Sample execution:
		- EXEC [dbo].[Task_DailySummaryLicPromotion_CheckData]
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
		[PromoDate] [date] NOT NULL,
		[TimeZone] [smallint] NOT NULL,
		[RptDateGMT] [date] NOT NULL,
		--------------------------------
		[BetCount_WonLose] [int] NULL,
		[Turnover_WonLose] [money] NULL,
		[BetCountOfPromoTime_WonLose] [int] NULL,
		[PromoInfo] [varchar](100) NULL
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
		[Turnover_WonLose] [money] NULL
	)
	CREATE UNIQUE CLUSTERED INDEX CIX_source_rptLicPromotion_Correct ON #source_rptLicPromotion_Correct(
		[PromoDate] ASC
		, [SiteID] ASC
		, [CurrencyID] ASC
		, [ProductID] ASC
		, [TimeZone] ASC
		, [RptDateGMT] ASC
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
		, @_PromoDate		= ISNULL(@PromoDate, @BalanceupDate)
		, @startTransdate	= @_PromoDate
		, @endTransdate		= DATEADD(DD, 1, CAST(@MovebetDate AS DATETIME))


	IF (@_PromoDate NOT BETWEEN @BalanceupDate AND @MovebetDate)
	BEGIN
		SELECT @Message = 'Invalid promo date ' + CAST(@_PromoDate AS VARCHAR(10))
		GOTO CLEANUP
	END

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
									WHERE '''''+ CAST(@_PromoDate AS VARCHAR(10)) +''''' >= p.StartDate AND '''''+ CAST(@MovebetDate AS VARCHAR(10)) +''''' <= p.EndDate
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
	--INNER JOIN @tempLicCurrency cur ON cs.currency = cur.CurrencyID
	WHERE cs.currency <> 20

	-- COLLECT BET Tickets vs PromoTime
	INSERT INTO #rptLicPromoBet(
		CustID,ProductID,PromoDate,TimeZone,RptDateGMT
		,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
	)
	SELECT
		-------------------Dimensions-------------
		b.srecommend AS CustID
		,promo.ProductID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT
		-------------------Measures-------------
		,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
		,SUM(promo.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
		,SUM(ABS(b.stake) * bet.IsWonLoseBet) AS Turnover_WonLose
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
		b.winlostdate > @MovebetDate AND b.winlostdate <= @today -- COVER cross day between transdate vs winlostdate
		AND b.statusID IN (112, 113)

	GROUP BY 
		b.srecommend
		,promo.ProductID
		,bet.PromoDate
		,bet.TimeZone
		,bet.RptDateGMT
	
	-- REMOVE unexpected PromoDate
	DELETE FROM #rptLicPromoBet
	WHERE PromoDate NOT BETWEEN @_PromoDate AND @MovebetDate

	--- CHECK & CORRECT upto BU date
	IF EXISTS(SELECT 1 FROM #rptLicPromoBet bet WHERE PromoDate <= @MovebetDate)
	BEGIN
		DECLARE @SuperIds TABLE (custID INT PRIMARY KEY, statusId BIT)
		DECLARE @batchSuper TABLE (custID INT PRIMARY KEY)
		DECLARE @promoDays TABLE (promodate SMALLDATETIME PRIMARY KEY)

		INSERT INTO @SuperIds
		SELECT DISTINCT CustID, 0 FROM #rptLicPromoBet
		WHERE PromoDate <= @MovebetDate

		INSERT INTO @promoDays
		SELECT DISTINCT PromoDate FROM #rptLicPromoBet
		WHERE PromoDate <= @MovebetDate

		WHILE EXISTS(SELECT 1 FROM @SuperIds WHERE statusId = 0)
		BEGIN
			-- RESET batch Super
			DELETE @batchSuper

			-- NEW batch Super
			UPDATE top(10) s
			SET statusId = 1
			OUTPUT deleted.custID
			INTO @batchSuper(custID)
			FROM @SuperIds s
			WHERE statusId = 0

			-- PROCESS data per batch
			INSERT INTO #rptLicPromoBet(
				CustID,ProductID,PromoDate,TimeZone,RptDateGMT
				,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
			)
			SELECT 
				b.srecommend AS custId
				,promo.ProductID
				,bet.PromoDate
				,bet.TimeZone
				,bet.RptDateGMT
				--------------------
				,SUM(bet.IsWonLoseBet) AS BetCount_WonLose
				,SUM(promo.IsPromoBet * bet.IsWonLoseBet) AS BetCountOfPromoTime_WonLose
				,SUM(b.stake) AS Turnover_WonLose 
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
			INNER JOIN @batchSuper cs ON b.srecommend = cs.CustID
			INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
			CROSS APPLY (
				SELECT 1 AS IsWonLoseBet 
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
			WHERE EXISTS(SELECT 1 FROM @promoDays d WHERE b.winlostdate >= d.promodate) -- COVER cross date between transdate and winlostdate
				AND b.statusID IN (112,113)
				
			GROUP BY 
				b.srecommend
				,promo.ProductID
				,bet.PromoDate
				,bet.TimeZone
				,bet.RptDateGMT
		END

		-- REMOVE unexpected PromoDate
		DELETE b
		FROM #rptLicPromoBet b
		WHERE NOT EXISTS(SELECT 1 FROM @promoDays t WHERE b.PromoDate = t.promodate)

		--- Merge bettrans & bettrans14
		INSERT INTO #source_rptLicPromotion_Correct(
			PromoDate,[SiteID],CurrencyID,[ProductID],TimeZone,RptDateGMT
			,BetCount_WonLose,BetCountOfPromoTime_WonLose,Turnover_WonLose
		)
		SELECT bet.PromoDate
			,[site].[SiteID]
			,lic.CurrencyID
			,bet.[ProductID]
			,bet.TimeZone
			,bet.RptDateGMT
			,SUM(bet.BetCount_WonLose)
			,SUM(bet.BetCountOfPromoTime_WonLose)
			,SUM(bet.Turnover_WonLose)
		FROM #rptLicPromoBet bet
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
			SELECT TOP(1000) * 
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
