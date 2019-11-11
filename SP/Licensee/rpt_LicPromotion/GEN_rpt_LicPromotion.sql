/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[GEN_rpt_LicPromotion]
	@fromDate DATE,
	@toDate DATE,
	@timeZone INT = 8
AS

/*
	Created: 20191014@Parsons
	Task: Generate data into rpt_LicPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		20190918@Parsons: LA - Non-peak hour promotion [Redmine: #119538]

	Param's Explanation:

	EXEC GEN_rpt_LicPromotion '20191001', '20191014'
*/
BEGIN
	DECLARE @DrawStatusId SMALLINT = 111, @WonStatusId SMALLINT = 112, @LoseStatusId SMALLINT = 113

	DELETE FROM dbo.rpt_LicPromotion
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

	--  dump fake data
	INSERT INTO #rptPromotion
	VALUES(1, '2019-10-07', '2019-10-07', 14, 16, 925144, 20, '2019-10-07', 8, '2019-10-08', 2, 2, 100),
	      (1, '2019-10-07', '2019-10-07', 14, 16, 925144, 20, '2019-10-07', 8, '2019-10-08', 1, 0, 0)

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
		   CurrencyID,
		   CASE WHEN bt.Bettype = 17000 THEN 37 ELSE 0 END AS ProductId,
		   SUM(CASE WHEN b.transdate BETWEEN DATEADD(HOUR, OffPeakStartTime, b.transdate) AND DATEADD(HOUR, OffPeakEndTime, b.transdate)
					THEN 1 ELSE 0 END) AS BetCountOfPromoTime,
		   SUM(CASE WHEN (b.transdate BETWEEN DATEADD(HOUR, OffPeakStartTime, b.transdate) AND DATEADD(HOUR, OffPeakEndTime, b.transdate))
						AND statusID != @DrawStatusId
					THEN 1 ELSE 0 END) AS BetCountOfPromoTime_NoDraw,
		   SUM(CASE WHEN CAST(pc.CouponDate AS DATE) = CAST(b.transdate AS DATE) THEN 1 ELSE 0 END) AS BetCount,
		   SUM(CASE WHEN CAST(pc.CouponDate AS DATE) = CAST(b.transdate AS DATE) AND statusID != @DrawStatusId THEN 1 ELSE 0 END) AS BetCount_NoDraw,
		   SUM(CASE WHEN CAST(pc.CouponDate AS DATE) = CAST(b.transdate AS DATE) THEN b.stake ELSE 0 END ) AS TurnoverPromoDay,
		   SUM(CASE WHEN CAST(pc.CouponDate AS DATE) = CAST(b.transdate AS DATE) AND statusID != @DrawStatusId THEN b.stake ELSE 0 END ) AS TurnoverPromoDay_NoDraw
	FROM #rptPromotion pc WITH(NOLOCK)
		 INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON pc.CustID = b.custid 
														AND b.transdate BETWEEN pc.StartDate AND pc.EndDate
														AND statusID IN (@DrawStatusId, @WonStatusId, @LoseStatusId)
		 INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
	WHERE @fromDate <= CAST(b.transdate AS DATE) AND CAST(b.transdate AS DATE) <= @toDate
	GROUP BY  pc.PromoID,
		   CAST(b.transdate AS DATE),
		   CAST(DATEADD(HOUR, @timeZone + 4, b.transdate) AS DATE),
		   pc.CustID,
		   CurrencyID,
		   CASE WHEN bt.Bettype = 17000 THEN 37 ELSE 0 END

	INSERT INTO rpt_LicPromotion(PromoID,RptDate,TimeZone,RptDateGMT,SiteID,CurrencyID,ProductID,CouponCount,RedemptionCount,RedemptionPrize,BetCountOfPromoTime,BetCountOfPromoTime_NoDraw,BetCount,BetCount_NoDraw,Turnover,Turnover_NoDraw)
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
		LEFT JOIN bodb02.dbo.[Site] s WITH (NOLOCK) ON c.[site] = s.[site]
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID
	GROUP BY b.PromoID, b.RptDate, b.RptDateGMT, ISNULL([site].SiteID, -1), b.CurrencyID, b.TimeZone, b.ProductId

	DROP TABLE #rptPromotion
	DROP TABLE #bettransData
END
GO