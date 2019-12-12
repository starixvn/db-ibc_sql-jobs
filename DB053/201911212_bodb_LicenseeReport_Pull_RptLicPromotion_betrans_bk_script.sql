/*
	Created: 201911212@Bobby
	DB: DB053.bodb_LicenseeReport
	Task: Repare data for the previous year [RedmineID #125358]
*/
use bodb_LicenseeReport
go
declare @cutoffDate smalldatetime
	, @promoDate	DATE
	, @endDate		smalldatetime

DECLARE @SPR_ProductID	INT = 37
	,@Timezone			TINYINT = 8

create table #rptLicPromotion_xpre
(
	RptDate date,
	CustId int,
	RptDateGMT date,
	BetCount Int,
	BetCount_WonLose Int,
	Turnover money,
	Turnover_WonLose money
)

SELECT @cutoffDate	= '20181213'
	 
SELECT @endDate		= DATEADD(DD, -1, MAX(Winlostdate))
from bodb02.dbo.bettrans14 b with(nolock) 

select @cutoffDate AS [@cutoffDate], @endDate AS [@endDate]

DECLARE @remoteQuery NVARCHAR(MAX)
set @promoDate = @cutoffDate

while @promoDate <= @endDate
begin
	
	DELETE #rptLicPromotion_xpre

	SET @remoteQuery = '\
		SELECT RptDate,	CustId,	RptDateGMT,	BetCount,BetCount_WonLose,Turnover,Turnover_WonLose
		FROM OPENQUERY([DBARC], ''SELECT * FROM bodb_archive.dbo.rptLicPromotion_xpre WHERE RptDate = '''''+CAST(@promoDate AS VARCHAR(10)) +''''''')
	'
	INSERT INTO #rptLicPromotion_xpre (RptDate,	CustId,	RptDateGMT,	BetCount,BetCount_WonLose,Turnover,Turnover_WonLose)
	EXEC sp_executesql @remoteQuery

	SELECT @promoDate AS [@promoDate], COUNT(1) from #rptLicPromotion_xpre

	;WITH cte_Bet AS (
		SELECT  [site].SiteID, cs.currency AS CurrencyID
			, b.RptDate, b.RptDateGMT
			, @Timezone AS Timezone
			, @SPR_ProductID AS ProductID
			, b.BetCount
			, b.BetCount_WonLose
			, b.Turnover
			, b.Turnover_WonLose
		FROM #rptLicPromotion_xpre b
		inner join bodb02.[dbo].[Dep_CustSuper] cs on b.custid = cs.custid AND cs.currency <> 20
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.[site] = [site].SiteName
	)
	merge dbo.RptLicPromotion as tgr
	using cte_Bet as src
	ON (tgr.SiteId = src.SiteId
		and tgr.CurrencyID = src.CurrencyID
		and tgr.RptDate = src.RptDate
		and tgr.Timezone = src.Timezone
		and tgr.RptDateGMT = src.RptDateGMT
		and tgr.ProductID = src.ProductID
	)
	when not matched by target and src.rptdate >= @cutoffDate then
		INSERT (RptDate,SiteID,CurrencyID,TimeZone,RptDateGMT,ProductID
			,BetCount
			,BetCount_WonLose
			,Turnover
			,Turnover_WonLose
		)
		VALUES(
			src.RptDate,src.SiteID,src.CurrencyID,src.TimeZone,src.RptDateGMT,src.ProductID
			,src.BetCount
			,src.BetCount_WonLose
			,src.Turnover
			,src.Turnover_WonLose
		)
	;

	SET @promoDate = DATEADD(DD,1,@promoDate)
end

drop table #rptLicPromotion_xpre

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT min([RptDate]), max([RptDate])
FROM [bodb_LicenseeReport].[dbo].[rptLicPromotion]