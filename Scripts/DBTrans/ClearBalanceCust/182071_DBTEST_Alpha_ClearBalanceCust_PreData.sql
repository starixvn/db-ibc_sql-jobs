/*<info serverAlias="DBTEST-bodb02"></info>*/
/*
	Created: 20230816@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalanceCust
	DB: DBTEST-bodb02
	Remark: Run on DBTEST
*/
USE [bodb02]
GO

with cte_setting AS (
	select distinct FromCustId, ToCustId
	from dbo.Transfer t with(nolock)
	inner join vw_Customer c with(nolock) on c.custid = t.CustId
	left join Dep_CustSuper cs with(nolock) on c.srecommend = cs.custid
	cross apply (
		select c.recommend, c.custid
		union
		select c.mrecommend, c.recommend
		union
		select c.srecommend, c.mrecommend
	) As ck (FromCustId, ToCustId)
	
	where Bettype IN ( 21003 , 21004)
		and cs.custid is null
		and t.WinlostDate = '2023-08-13'
		AND ck.FromCustId > 0 and ck.ToCustId > 0
)
insert into CustDB.dbo.[Age_ClearBalanceCust_Setting](
	[FromCustID],
	[ToCustID],
	[CreatedDate],
	[EffectiveDate],
	[Creator]
)
select  
	[FromCustID],
	[ToCustID],
	'2023-08-01' AS [CreatedDate],
	'2023-08-01' AS [EffectiveDate],
	8 AS [Creator]
FROM cte_setting
GO

--- Move transfer to temp table
select  t.*
INTO dbo.Transfer_20230813_tmp
from Transfer t with(nolock)
inner join CustDB.dbo.[dbo].[Age_ClearBalanceCust_Setting] st with(nolock)
	ON t.CustId IN ([FromCustID], [ToCustID])
WHERE t.WinlostDate = '2023-08-13'
	AND t.Bettype IN (21003 , 21004)

go


DELETE t
FROM dbo.Transfer t
INNER JOIN dbo.Transfer_20230813_tmp tmp ON tmp.TransId = t.TransId