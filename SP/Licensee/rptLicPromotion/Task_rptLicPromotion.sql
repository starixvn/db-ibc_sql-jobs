/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[Task_rptLicPromotion]
	@fromDate DATE,
	@toDate DATE,
	@timeZone INT = 8
AS

/*
	Created: 20191014@Parsons
	Task: Generate data into rptLicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		20190918@Parsons: LA - Non-peak hour promotion [Redmine: #119538]

	Param's Explanation:

	EXEC Task_rptLicPromotion '20191001', '20191014'
*/
BEGIN
	DECLARE @DrawStatusId SMALLINT = 111
	DECLARE @NonPeakHourPromoId INT = 37

	DELETE FROM dbo.rptLicPromotion
	WHERE @fromDate <= RptDate  AND RptDate <= @toDate

	CREATE TABLE #rptPromotion(
		PromoID	int,
		StartDate date,
		EndDate date,
		OffPeakStartTime tinyint,
		OffPeakEndTime tinyint,
		CustID int,
		CurrencyID	int,
		CouponDate date,
		CouponTimeZone int,
		CouponDateGMT date,
		CouponCount int,
		RedemptionCount int,
		RedemptionPrize money)

	DECLARE @count int, @tmpDate date
	SELECT @count = DATEDIFF(DAY,@fromDate,@toDate)
	WHILE (@count >= 0)
	BEGIN
		SELECT @tmpDate=DATEADD(DAY,@count,@fromDate)
		INSERT INTO #rptPromotion(PromoID,StartDate,EndDate,OffPeakStartTime,OffPeakEndTime,CustID,CurrencyID,CouponDate,CouponTimeZone,CouponDateGMT,CouponCount,RedemptionCount,RedemptionPrize)
		EXEC ('CALL Promotion.Intg_LA_GetPromoSummary('''+@tmpDate+''');') at DBPROMO

		SELECT @count = @count - 1
	END
	CREATE TABLE #bettransData(
		PromoID	int,
		RptDate date,
		RptDateGMT date,
		TimeZone int,
		CustId int,
		CurrencyID	int,
		ProductId int,
		BetCountOfPromoTime int,
		BetCountOfPromoTime_NoDraw int,
		BetCount int,
		BetCount_NoDraw int,
		Turnover money,
		Turnover_NoDraw money)

	INSERT INTO #bettransData(PromoID, 
								RptDate, 
								RptDateGMT,
								TimeZone, 
								CustId, 
								CurrencyID,
								ProductId,
								BetCountOfPromoTime, 
								BetCountOfPromoTime_NoDraw, 
								BetCount, 
								BetCount_NoDraw,
								Turnover,
								Turnover_NoDraw)
	SELECT pc.PromoID,
		   CAST(b.transdate AS DATE) RptDate,
		   CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE) RptDateGMT,
		   @timeZone,
		   pc.CustID,
		   b.currency AS CurrencyID,
		   @NonPeakHourPromoId,
		   SUM(CASE WHEN b.transdate BETWEEN DATEADD(HOUR, OffPeakStartTime, pc.CouponDate) AND DATEADD(HOUR, OffPeakEndTime, pc.CouponDate) 
					THEN 1 ELSE 0 END) AS BetCountOfPromoTime,
		   SUM(CASE WHEN b.transdate BETWEEN DATEADD(HOUR, OffPeakStartTime, pc.CouponDate) AND DATEADD(HOUR, OffPeakEndTime, pc.CouponDate) AND statusID <> @DrawStatusId
					THEN 1 ELSE 0 END) AS BetCountOfPromoTime_NoDraw,
		   SUM(CASE WHEN DATEDIFF(DAY, pc.CouponDate, b.transdate) = 0 THEN 1 ELSE 0 END) AS BetCount,
		   SUM(CASE WHEN DATEDIFF(DAY, pc.CouponDate, b.transdate) = 0 AND statusID <> @DrawStatusId THEN 1 ELSE 0 END) AS BetCount_NoDraw,
		   SUM(CASE WHEN DATEDIFF(DAY, pc.CouponDate, b.transdate) = 0 THEN b.stake ELSE 0 END ) AS TurnoverPromoDay,
		   SUM(CASE WHEN DATEDIFF(DAY, pc.CouponDate, b.transdate) = 0 AND statusID <> @DrawStatusId THEN b.stake ELSE 0 END ) AS TurnoverPromoDay_NoDraw
	FROM #rptPromotion pc WITH(NOLOCK)
		 INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON pc.CustID = b.custid 
														AND CAST(b.transdate AS DATE) BETWEEN pc.StartDate AND pc.EndDate
		 INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
	WHERE @fromDate <= b.transdate AND b.transdate < DATEADD(Day,1,@toDate)
		  AND CurrencyID <> 20 
	GROUP BY  pc.PromoID,
		   CAST(b.transdate AS DATE),
		   CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE),
		   pc.CustID,
		   b.currency

	INSERT INTO rptLicPromotion(PromoID,RptDate,TimeZone,RptDateGMT,SiteID,CurrencyID,ProductID,CouponCount,RedemptionCount,RedemptionPrize,BetCountOfPromoTime,BetCountOfPromoTime_NoDraw,BetCount,BetCount_NoDraw,Turnover,Turnover_NoDraw)
	SELECT b.PromoID, b.RptDate, b.TimeZone, b.RptDateGMT, ISNULL([site].SiteID, -1), b.CurrencyID, b.ProductId,
									SUM(ISNULL(CouponCount, 0)),
									SUM(ISNULL(RedemptionCount, 0)),
									SUM(ISNULL(RedemptionPrize, 0)),
									SUM(BetCountOfPromoTime),
									SUM(BetCountOfPromoTime_NoDraw),
									SUM(BetCount),
									SUM(BetCount_NoDraw),
									SUM(Turnover),
									SUM(Turnover_NoDraw)
	FROM #bettransData b
		LEFT JOIN #rptPromotion pc ON b.PromoID = pc.PromoID AND  
										b.CustId = pc.CustID AND 
										b.CurrencyID = pc.CurrencyID AND
										b.TimeZone = pc.CouponTimeZone AND
										b.RptDate = pc.CouponDate AND
										b.RptDateGMT = pc.CouponDateGMT
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON pc.CustID= c.custid
		LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON c.srecommend = cs.custid
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.site = site.SiteName
	GROUP BY b.PromoID, b.RptDate, b.RptDateGMT, ISNULL([site].SiteID, -1), b.CurrencyID, b.TimeZone, b.ProductId

	DROP TABLE #rptPromotion
	DROP TABLE #bettransData
END
GO