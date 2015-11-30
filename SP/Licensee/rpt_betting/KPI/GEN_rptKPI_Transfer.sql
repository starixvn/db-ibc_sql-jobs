USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GEN_rptKPI_Transfer]    Script Date: 01/26/2015 23:36:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.GEN_rptKPI_Transfer    Script Date: 9/7/2012 9:38:02 AM ******/
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
insert into #transfer(transdate,[site],currency,custid,amount)
	select 
		convert(varchar(10),transdate,120) as transdate,
		isnull(Site.SiteID,-1) as [site], 
		b.currency,
		b.custid,
		sum(b.amount) amount
	from dbo.tbl_Customer_Account b (nolock)
		inner join bodb02.dbo.customer cus (nolock) on b.custid = cus.custid and cus.roleid = 1
		inner join bodb02.dbo.customer cus_a (nolock) on cus.recommend = cus_a.custid 
		left join dbo.view_site_list Site (nolock) on cus_a.site = Site.SiteName
	where
		transdate >= @datefrom and transdate < @dateto
		and ((transtype = 22001 and amount > 0) /*or (transtype = 22005 and amount > 0)*/)
		and not exists (
			select *
			from dbo.tbl_Customer_Account (nolock)
			where 
				transdate >= @datestart
				and convert(varchar(10),transdate,120) < convert(varchar(10),b.transdate,120)
				and custid = b.custid
				and ((transtype = 22001 and amount > 0) /*or (transtype = 22005 and amount > 0)*/)
		)
	group by 
		convert(varchar(10),transdate,120),
		isnull(Site.SiteID,-1), 
		b.currency,
		b.custid

update tr 
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


