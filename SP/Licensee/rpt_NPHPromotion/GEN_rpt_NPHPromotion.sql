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

	INSERT INTO #tmpData(RptDate, RptDate3rd, SiteID, CurrencyID, Redeemed, CouponCount, Prize)
	SELECT CAST(pc.CreateTime AS DATE),
		   CAST(DATEADD(HOUR, 12, pc.CreateTime) AS DATE),
		   ISNULL([site].SiteID, -1),
		   CurrencyID,
		   Redeemed,
		   COUNT(*),
		   SUM(Prize)
	FROM bodb02.dbo.NPHPromotion p WITH(NOLOCK)
		INNER JOIN bodb02.dbo.NPHPromoCoupon pc WITH(NOLOCK) ON p.PromoID = pc.PromoID
		LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON pc.CustID= c.custid
		LEFT JOIN bodb02.dbo.[Site] s WITH (NOLOCK) ON c.[site] = s.[site]
		LEFT JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON s.siteid = site.IbcSiteID		
	WHERE @fromDate <= pc.CreateTime AND pc.CreateTime <= @toDate
	GROUP BY  CAST(pc.CreateTime AS DATE),
			  CAST(DATEADD(HOUR, 12, pc.CreateTime) AS DATE),
		      ISNULL([site].SiteID, -1),
			  CurrencyID,
			  Redeemed

	-- Update value 
	UPDATE t
	SET t.BetCountOfNPH = 0,
		t.BetCountOfPromoDay = 0,
		t.TurnoverPromoDay = 0
	FROM #tmpData t

	INSERT INTO dbo.rpt_NPHPromotion(RptDate,RptDate3rd,SiteID,CurrencyID,CouponCount,Redeemed,Prize,BetCountOfNPH,BetCountOfPromoDay,TurnoverPromoDay)
	SELECT RptDate,RptDate3rd,SiteID,CurrencyID,CouponCount,Redeemed,Prize,BetCountOfNPH,BetCountOfPromoDay,TurnoverPromoDay
	FROM #tmpData

	DROP TABLE #tmpData
END
GO