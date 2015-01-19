USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_MonthlySummaryClickRate]    Script Date: 01/16/2015 03:45:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Aff_MonthlySummaryClickRate]
	@date smalldatetime
AS
/*
  Task to summary Click Statistics Monthly
  Writer : Peter
  Date : 2009/05/04
  DB: DB052.Affiliate_12BET
*/
 SET NOCOUNT ON
 
select @date = convert(varchar(10), @date, 120)
if(exists (select 1 from ClickStatisticsSum (nolock) where datediff(mm,@date,[Date])=0))
 begin
   return
 end 
 
 --Summary for Daily by TrackingID and Date
insert into ClickStatisticsSum(AffID,TrackingID,[Date],TotalClick,UniqueClick,IsForMonth)
select a.AffID,t.TrackingID,t.[Date],t.TotalClick,t.UniqueClick,t.IsForMonth
from(
select TrackingID,[Date],sum(1) as TotalClick,count(distinct IP) as UniqueClick,0 as IsForMonth
from ClickStatistics (nolock)
where datediff(mm,@date,date)=0
group by TrackingID,Date) t
inner join TrackingCode a (nolock)  on a.TrackingID=t.TrackingID

--Summary for Monthly by TrackingID -each TrackingID will have one row for this month
insert into ClickStatisticsSum(AffID,TrackingID,[Date],TotalClick,UniqueClick,IsForMonth)

select a.AffID,t.TrackingID,t.[Date],t.TotalClick,t.UniqueClick,t.IsForMonth
from(
select TrackingID,cast(year([Date]) as varchar(6)) + '-' + cast(month([Date]) as varchar(2)) + '-01' as Date,sum(1) as TotalClick,count(distinct IP) as UniqueClick,1 as IsForMonth
from ClickStatistics (nolock)
where datediff(mm,@date,date)=0 
group by TrackingID,month([Date]),year([Date])
) t
inner join TrackingCode a (nolock)  on a.TrackingID=t.TrackingID




--Summary for Daily All
insert into ClickStatisticsSum(AffID,TrackingID,[Date],TotalClick,UniqueClick,IsForMonth)
select a.AffID,0 as TrackingID,s.[Date],sum(1) as TotalClick,count(distinct s.IP) as UniqueClick,0 as IsForMonth
from ClickStatistics s (nolock)
     inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID
where datediff(mm,@date,s.date)=0
group by a.AffID,s.Date

--Summary for Monthly All
insert into ClickStatisticsSum(AffID,TrackingID,[Date],TotalClick,UniqueClick,IsForMonth)
select a.AffID,0 as TrackingID,cast(year(s.Date) as varchar(6)) + '-' + cast(month(s.Date) as varchar(2)) + '-01' as Date,sum(1) as TotalClick,count(distinct s.IP) as UniqueClick,1 as IsForMonth
from ClickStatistics s (nolock)
 inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID
where datediff(mm,@date,s.date)=0 
group by a.AffID,month(s.Date),year(s.Date)


insert into ClickStatistics_bk
select * from ClickStatistics
where datediff(mm,@date,date)=0

delete ClickStatistics
where datediff(mm,@date,date)=0

GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlySummaryClickRate] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlySummaryClickRate] TO [vnteam] AS [dbo]
GO


