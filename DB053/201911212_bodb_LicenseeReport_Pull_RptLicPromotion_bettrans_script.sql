/*
	Created: 201911212@Bobby
	DB: DB053.bodb_LicenseeReport
	Task: Repare data for previous year [RedmineID #125358]
*/
use bodb_LicenseeReport
go
declare @cutoffDate smalldatetime
	, @promoDate	smalldatetime
	, @endDate		smalldatetime

DECLARE @SPR_ProductID	INT = 37
	,@Timezone			TINYINT = 8

SELECT @cutoffDate	= DATEADD(DD, 1, MAX(Winlostdate))
	, @endDate		= '20191212'
from bodb02.dbo.bettrans14 b with(nolock) 

select @cutoffDate AS [@cutoffDate], @endDate AS [@endDate]

set @promoDate = @cutoffDate
while @promoDate <= @endDate
begin
	SELECT @promoDate AS [@promoDate]
	;with cte_Bet AS (
		select [site].SiteID, cs.currency AS CurrencyID
			, cast(transdate as date) AS RptDate, CAST(DATEADD(HOUR, @Timezone + 4, transdate) AS DATE) as RptDateGMT
			, @Timezone AS Timezone
			, @SPR_ProductID AS ProductID
			, count(1) as BetCount
			, SUM(case when statusID IN(112,113) then 1 else 0 end) as BetCount_WonLose
			, SUM(stake) as Turnover
			, SUM(case when statusID IN(112,113) then stake else 0 end) as Turnover_WonLose
		from bodb02.dbo.bettrans b with(nolock)
		inner join bodb02.[dbo].[Dep_CustSuper] cs on b.srecommend = cs.custid AND cs.currency <> 20
		INNER JOIN bodb_licensee.dbo.view_site_list [site] (NOLOCK) ON cs.[site] = [site].SiteName
		INNER JOIN bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB') bt ON b.Bettype = bt.Bettype
		where b.winlostdate = @promoDate
		group by [site].SiteID, cs.currency
			,cast(transdate as date)
			,CAST(DATEADD(HOUR, @Timezone + 4, transdate) AS DATE)
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
	when matched then
		update 
		set tgr.betcount			+= ISNULL(src.betcount, 0)
			,tgr.BetCount_WonLose	+= ISNULL(src.BetCount_WonLose, 0)
			,tgr.Turnover			+= ISNULL(src.Turnover, 0)
			,tgr.Turnover_WonLose	+= ISNULL(src.Turnover_WonLose, 0)

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

	set @promoDate = DATEADD(DD,1,@promoDate)
end

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT min([RptDate]), max([RptDate])
FROM [bodb_LicenseeReport].[dbo].[rptLicPromotion]