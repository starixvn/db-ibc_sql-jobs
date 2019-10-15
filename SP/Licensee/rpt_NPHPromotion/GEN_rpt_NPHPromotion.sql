/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[GEN_rpt_NPHPromotion]
	@fromDate DATE,
	@toDate DATE
AS

/*
	Created: 20191014@Parsons
	Task: Generate data into rpt_NPHPromotion 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		20190918@Parsons: LA - Non-peak hour promotion [Redmine: #119538]

	Param's Explanation:

	EXEC GEN_rpt_NPHPromotion '20191001', '20191014'
*/
BEGIN

	DELETE FROM dbo.rpt_NPHPromotion
	WHERE @fromDate <= RptDate  AND RptDate <= @toDate

	CREATE TABLE #tmpData(
		PromoID	int,
		RptDate date,
		RptDate3rd date,
		SiteID int,
		CurrencyID int,
		CouponCount int,
		Redeemed bit,
		Prize money,
		BetCountOfNPH int,
		BetCountOfPromoDay int,
		TurnoverPromoDay money)

	INSERT INTO #tmpData(PromoID, RptDate, RptDate3rd, SiteID, CurrencyID, Redeemed, BetCountOfNPH/*, BetCountOfPromoDay, TurnoverPromoDay*/)
	SELECT pc.PromoID,
		   CAST(pc.CreateTime AS DATE),
		   CAST(DATEADD(HOUR, 12, pc.CreateTime) AS DATE),
		   ISNULL([site].SiteID, -1),
		   CurrencyID,
		   Redeemed,
		   SUM(CASE WHEN b.transdate BETWEEN DATEADD(HOUR, OffPeakStartTime, b.transdate) AND DATEADD(HOUR, OffPeakEndTime, b.transdate)
					  /*Date between StartDate AND EndDate, Time between OffPeakStartTime AND OffPeakEndTime */ THEN 1 ELSE 0 END)
	FROM bodb02.dbo.NPHPromoCoupon pc WITH(NOLOCK)
		INNER JOIN bodb02.dbo.NPHPromotion p WITH(NOLOCK) ON p.PromoID = pc.PromoID
		LEFT JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON pc.CustID = b.custid
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON pc.CustID= c.custid
		LEFT JOIN bodb02.dbo.[Site] s WITH (NOLOCK) ON c.[site] = s.[site]
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID		
	WHERE @fromDate <= pc.CreateTime AND pc.CreateTime <= @toDate
		--AND b.transdate BETWEEN p.StartDate AND p.EndDate	
	GROUP BY  pc.PromoID,
			  CAST(pc.CreateTime AS DATE),
			  CAST(DATEADD(HOUR, 12, pc.CreateTime) AS DATE),
		      ISNULL([site].SiteID, -1),
			  CurrencyID,
			  Redeemed
	ORDER BY CAST(pc.CreateTime AS DATE)

	-- Update value
	;WITH cte_CouponSummary AS(
		SELECT t.PromoID, CAST(pc.CreateTime AS DATE) AS CreateTime, COUNT(pc.CouponID) AS CouponCount, SUM(pc.Prize) AS Prize
		FROM #tmpData t
		INNER JOIN bodb02.dbo.NPHPromoCoupon pc WITH(NOLOCK) ON t.PromoID = pc.PromoID AND t.RptDate = CAST(pc.CreateTime AS DATE) 
		GROUP BY t.PromoID, CAST(pc.CreateTime AS DATE)
	) 
	UPDATE t
	SET t.BetCountOfNPH = 0,
		t.BetCountOfPromoDay = 0,
		t.TurnoverPromoDay = 0,
		t.CouponCount = cte.CouponCount,
		t.Prize = cte.Prize
	FROM #tmpData t
	INNER JOIN cte_CouponSummary cte ON  t.PromoID = cte.PromoID AND t.RptDate = cte.CreateTime
	
	INSERT INTO dbo.rpt_NPHPromotion(RptDate,RptDate3rd,SiteID,CurrencyID,Redeemed,CouponCount,Prize,BetCountOfNPH,BetCountOfPromoDay,TurnoverPromoDay)
	SELECT RptDate,RptDate3rd,SiteID,CurrencyID,Redeemed,SUM(CouponCount),SUM(Prize),SUM(BetCountOfNPH),SUM(BetCountOfPromoDay),SUM(TurnoverPromoDay)
	FROM #tmpData
	GROUP BY RptDate,RptDate3rd,SiteID,CurrencyID, Redeemed

	DROP TABLE #tmpData
END
GO

--SELECT CAST (getdate() as time), CAST('17:30:00.0000000' AS TIME), cast ('12:00' as time), DATEADD(HOUR, 16, '2019-10-14')

--SELECT CONVERT(varchar(15),CAST('17:30:00.0000000' AS TIME),100)
