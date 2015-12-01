
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GEN_rptKPI_Transfer    Script Date: 12/1/2015 2:38:01 AM ******/

CREATE PROCEDURE [dbo].[GEN_rptKPI_Transfer]
    @datefrom datetime, 
    @dateto datetime = -1
AS
/*
    Created: 20110517@Don
    Task: Generate data into rptKPI_Transfer from bodb_Licensee.dbo.tbl_Customer_Account
    DB: DBO52.bodb_Licensee

    Revisions:
        - 20120711@Don: Fixed a bug about updating value of FirstTransferInCount and FirstTransferInAmt
		- 20151118@Percy: Enhance performace [RedmineID: #46815]
		- 20151124@Francis: Revise sp to run day by day to enhance performance
        
    Param's Explanation:

*/
create table #transfer(transdate datetime,[site] int,currency int,custid int,amount money)

if @dateto = -1 select @dateto = @datefrom
select @dateto = DATEADD(day,1,@dateto)

declare @datestart datetime
select @datestart = '20090701' -- production: '20090701'


delete dbo.rptKPI_Transfer where rptDate >= @datefrom and rptDate < @dateto


-- ****** TransferInCount, TransferOutCount ******
insert into dbo.rptKPI_Transfer(rptDate,SiteID,CurrencyID,TransferInCount,TransferOutCount)
select
	t.transdate,
	t.[site],
	t.currency,
    isnull(t.TransferInCount,0),
    isnull(t.TransferOutCount,0)
from 
	(
    select 
        cast(convert(varchar(10),transdate,120) as datetime) as transdate,
        isnull(Site.SiteID,-1) as [site], 
        b.currency,
        sum(
	        case 
		        when (/*(b.transtype = 22005 and b.amount > 0) or*/ (b.transtype = 22001 and b.amount > 0)) then 1
		        else 0
	        end
        ) as TransferInCount,
        sum(
            case 
		        when (/*(b.transtype = 22005 and b.amount < 0) or*/ (b.transtype = 22002 and b.amount < 0)) then 1
		        else 0
	        end
        ) as TransferOutCount
    from dbo.tbl_Customer_Account b (nolock)
        inner join bodb02.dbo.customer cus (nolock) on b.custid = cus.custid and cus.roleid = 1
        inner join bodb02.dbo.customer cus_a (nolock) on cus.recommend = cus_a.custid 
        left join dbo.view_site_list Site (nolock) on cus_a.site = Site.SiteName
    where
        transdate >= @datefrom and transdate < @dateto
        and (transtype = 22001 or transtype = 22002 /*or transtype = 22005*/)
    group by 
        convert(varchar(10),transdate,120),
        isnull(Site.SiteID,-1),
        b.currency
	) t
-- ****** FirstTransferInCount, FirstTransferInAmt ******
declare @datetmp datetime
set @datetmp = @datefrom
while (@datetmp < @dateto)
begin
	 /*
	 select CONVERT(DATE,b.transdate) AS transdate ,
		  isnull(Site.SiteID,-1) as [site], 
		  b.currency,
		  b.custid,
		  b.amount
	 into #tmp1
	 from dbo.tbl_Customer_Account b (nolock)
	  inner join bodb02.dbo.customer cus (nolock) on b.custid = cus.custid and cus.roleid = 1
	  inner join bodb02.dbo.customer cus_a (nolock) on cus.recommend = cus_a.custid---- and cus_a.roleid = 2
	  left join dbo.view_site_list Site (nolock) on cus_a.site = Site.SiteName
	 where
	  transdate >= @datetmp and transdate < dateadd(dd,1,@datetmp)
	  and (transtype = 22001 and amount > 0)
	  
	 select custid, CONVERT(DATE,b.transdate) AS transdate 
	 into #tmp2
	 from dbo.tbl_Customer_Account  b with (nolock)
	 where transdate >= @datestart and transdate < dateadd(dd,1,@datetmp)
	  and (b.transtype = 22001 and b.amount > 0)

	 create index inx_temp1 ON #tmp1 (custid) 
	 create index inx_temp2 ON #tmp2 (custid, transdate) 
	 
	 insert into #transfer(transdate,[site],currency,custid,amount)
	 SELECT T1.transdate, T1.site,  T1.currency,  T1.custid, SUM (T1.amount) as Amount 
	 FROM #tmp1 T1
	 WHERE NOT EXISTS
	 (SELECT 1 FROM #tmp2 b WHERE b.custid = T1.custid and T1.transdate > b.transdate)
	 GROUP BY T1.transdate, T1.site,  T1.currency,  T1.custid

	 DROP TABLE #tmp1
	 DROP TABLE #tmp2
	 */
	select convert(date, b.transdate) as transdate ,
		isnull(Site.SiteID,-1) as [site], 
		b.currency,
		b.custid,
		b.amount
	into #tmp1
	from dbo.tbl_Customer_Account b (nolock)
		inner join bodb02.dbo.customer cus (nolock) on b.custid = cus.custid and cus.roleid = 1
		inner join bodb02.dbo.customer cus_a (nolock) on cus.recommend = cus_a.custid
		left join dbo.view_site_list Site (nolock) on cus_a.site = Site.SiteName
	where
		transdate >= @datetmp and transdate < dateadd(dd,1,@datetmp)
		and (transtype = 22001 and amount > 0)

	create index inx_temp1 on #tmp1 (custid) 

	select  T1.transdate,			
			T1.custid
	into  #tmp2
	from #tmp1 T1 
	where exists (select 1 from dbo.tbl_Customer_Account b (nolock) 
	where T1.custid = b.custid AND b.transdate < T1.transdate AND  b.transdate >= @datestart and b.transdate < dateadd(dd,1,@datetmp)
		and (b.transtype = 22001 and b.amount > 0))
		
	create index inx_temp2 on #tmp2 (custid, transdate) 

	insert into #transfer(transdate,[site],currency,custid,amount)
		select T1.transdate, T1.site,  T1.currency,  T1.custid, SUM ( T1.amount) as Amount 
		from #tmp1 T1
		where not exists
		(select 1 from #tmp2 T2 where T2.custid = T1.custid and T1.transdate = T2.transdate)
		group by T1.transdate, T1.site,  T1.currency,  T1.custid

	drop table #tmp1
	drop table #tmp2
	 	
	
	set @datetmp = dateadd(dd,1,@datetmp)			
end

update tr with (rowlock, updlock)
set 
    tr.FirstTransferInCount = isnull(t1.FirstTransferInCount,0),
    tr.FirstTransferInAmt = isnull(t1.FirstTransferInAmt,0)
from 
    (
        select 
			t.transdate,
			t.site,
			t.currency,
		    
			count(*) as FirstTransferInCount,
			sum(t.amount) as FirstTransferInAmt
		from #transfer t
		group by
			t.transdate,
			t.site,
			t.currency
    ) t1
    left join dbo.rptKPI_Transfer tr on tr.rptDate = t1.transdate and tr.siteID = t1.site and tr.currencyID = t1.currency
    
drop table #transfer

--update MTD table
exec dbo.GEN_RptKPI_MTD_Transfer
    @date = @datefrom, 
    @date2 = @dateto
    
/*exec [dbo].[GEN_RptKPI_MTD]
    @date = @datefrom, 
    @date2 = @dateto,
    @stattype = 1*/



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[GEN_rptKPI_Transfer] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[GEN_rptKPI_Transfer] TO [vnteam]
GO 
