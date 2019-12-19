/*
	Created: 201911212@Bobby
	DB: DB06x.bodb_archive
	Task: Re-genertae data up to 2018-12-13 previous year [RedmineID #125358]
*/
use bodb_archive
go
declare @cutoffDate smalldatetime
	, @promoDate	smalldatetime
	, @endDate		smalldatetime

SELECT @cutoffDate	= '20181213'
	 
SELECT @endDate		= MAX(Winlostdate)
from dbo.bettrans_bk b with(nolock) 

select @cutoffDate AS [@cutoffDate], @endDate AS [@endDate]

set @promoDate = @cutoffDate
while @promoDate <= @endDate
begin
	
	SELECT @promoDate AS [@promoDate]

	;with cte_bettype AS --> SB only
	(
		SELECT distinct typeid
		FROM bodb02.dbo.bettype WITH (NOLOCK)
		WHERE (typeid < 31
			OR typeid BETWEEN 121 AND 999
			OR typeid BETWEEN 9001 AND 9399
			OR typeid BETWEEN 1301 AND 1399
			OR typeid = 38 -- BetBuilder
		)
		AND typeid NOT IN (901, 902, 903,904, 911, 912, 913, 914) -- Bettrade bettypes 
	),
	cte_Bet AS (
		select cs.custid, cast(transdate as date) AS RptDate, CAST(DATEADD(HOUR, 12, transdate) AS DATE) as RptDateGMT
			, count(1) as BetCount
			, SUM(case when statusID IN(112,113) then 1 else 0 end) as BetCount_WonLose
			, SUM(stake) as Turnover
			, SUM(case when statusID IN(112,113) then stake else 0 end) as Turnover_WonLose
		from dbo.bettrans_bk b with(nolock)
		inner join bodb02.[dbo].[Dep_CustSuper] cs on b.srecommend = cs.custid AND cs.currency <> 20
		inner join cte_bettype bt ON b.bettype = bt.bettype
		where b.winlostdate = @promoDate
		group by cs.custid, cast(transdate as date)
			,CAST(DATEADD(HOUR, 12, transdate) AS DATE)
	)
	merge dbo.rptLicPromotion_xpre as tgr
	using cte_Bet as src
	ON (
		tgr.rptdate = src.rptdate
		and tgr.custid = src.custid
		and tgr.RptDateGMT = src.RptDateGMT
	)
	when matched then
		update 
		set tgr.betcount			+= ISNULL(src.betcount, 0)
			,tgr.BetCount_WonLose	+= ISNULL(src.BetCount_WonLose, 0)
			,tgr.Turnover			+= ISNULL(src.Turnover, 0)
			,tgr.Turnover_WonLose	+= ISNULL(src.Turnover_WonLose, 0)

	when not matched by target and src.rptdate >= @cutoffDate then
		insert (custid, rptdate, RptDateGMT, BetCount,BetCount_WonLose,Turnover,Turnover_WonLose)
		values(custid, rptdate, RptDateGMT, BetCount,BetCount_WonLose,Turnover,Turnover_WonLose)
	;

	set @promoDate = DATEADD(DD,1,@promoDate)
end