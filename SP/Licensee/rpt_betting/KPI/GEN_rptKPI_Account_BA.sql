USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_rptKPI_Account_BA]
    @datefrom datetime, 
    @dateto datetime = -1
AS
/*
Created: 20111107@Don
Task: Generate data into rptKPI_Account_BA from Staging
DB: DBLIC.bodb_LicenseeReport

Revisions:
20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]   
Param's Explanation:

*/

/*
create table #TotalOnline
(
    LogDate smalldatetime,
    ServerID varchar(10),
    Users int
)
*/

if @dateto = -1 select @dateto = @datefrom
select @dateto = DATEADD(day,1,@dateto)

declare @date smalldatetime, @date2 smalldatetime
select @date = @datefrom, @date2 = @dateto


delete dbo.rptKPI_Account_BA where rptDate >= @date and rptDate < @date2


insert into dbo.rptKPI_Account_BA(rptDate,[hour],siteid,UniqueBettorCount)
    select 
        convert(varchar(10),transdate,120) rptDate,
        datepart(hour,transdate) [hour],
        isnull(s.SiteID,-1) siteid,
        
        count(distinct bet.custid) UniqueBettorCount
    from dbo.bettrans bet (nolock)
        inner join bodb02.dbo.Customer cust (nolock) on bet.custid = cust.custid
        inner join bodb02.dbo.Customer cust_a (nolock) on cust.recommend = cust_a.custid
        left join bodb02.dbo.Site ibcsite with (nolock) on cust_a.site=ibcsite.site
	    left join bodb_Licensee.dbo.view_site_list s with (nolock) on ibcsite.siteid=s.IbcSiteID
    where 
        transdate >= @date and transdate < @date2
        and isBA = 1
    group by 
        convert(varchar(10),transdate,120),
        datepart(hour,transdate),
        isnull(s.SiteID,-1)


/*
if ( exists(select * from db03.on_user.dbo.TotalOnline with(nolock) where logdate >= @date and logdate < @date2) )
    insert into #TotalOnline(LogDate,ServerID,Users)
        select logdate, left(cast(serverid as varchar(10)),3), users
        from db03.on_user.dbo.TotalOnline with(nolock)
        where logdate >= @date and logdate < @date2

if ( exists(select * from db03.on_user.dbo.TotalOnline_BK with(nolock) where logdate >= @date and logdate < @date2) )
    insert into #TotalOnline(LogDate,ServerID,Users)
        select logdate, left(cast(serverid as varchar(10)),3), users
        from db03.on_user.dbo.TotalOnline_BK with(nolock)
        where logdate >= @date and logdate < @date2


update acc
set acc.PeakBettorCount = isnull(t.PeakBettorCount,0)
from dbo.rptKPI_Account_BA acc
    left join
    (
        select 
            cast(convert(varchar(10),online.logdate,120) as datetime) as rptDate,
            datepart(hour,online.logdate) as [hour],
            isnull(s.siteid,-1) as [siteid],
            
            sum(online.users) as PeakBettorCount
        from
            #TotalOnline online (nolock)
            left join 
            (
                select isnull(vs.SiteID,-1) siteid, left(serverid,3) serverid
                from bodb02.dbo.Site s (nolock)
                    left join dbo.view_site_list vs (nolock) on s.siteid = vs.IbcSiteID
            ) s on online.serverid = s.serverid
        group by
            convert(varchar(10),online.logdate,120),
            datepart(hour,online.logdate),
            isnull(s.siteid,-1)
    ) t on acc.rptDate = t.rptDate and acc.hour = t.hour and acc.siteid = t.siteid
    
drop table #TotalOnline
*/

--update MTD table
exec dbo.GEN_RptKPI_MTD_Account
    @date = @date, 
    @date2 = @date2,
    @isBA = 1
    
/*exec [dbo].[GEN_RptKPI_MTD]
    @date = @date, 
    @date2 = @date2,
    @stattype = 3,
    @isBA = 1*/
GO
GRANT EXECUTE ON [dbo].[GEN_rptKPI_Account_BA] TO [bodbLicenseeNet] AS [dbo]