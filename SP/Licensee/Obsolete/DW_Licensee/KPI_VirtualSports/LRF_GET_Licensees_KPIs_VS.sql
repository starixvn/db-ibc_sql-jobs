 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

---[LRF_GET_Licensees_KPIs_VS] @ReportDate='2012-11-08'
ALTER PROCEDURE [dbo].[LRF_GET_Licensees_KPIs_VS]
    @ReportDate datetime = NULL
AS
/*
    Created: 20121109@Jim
    Task: OWA - Add Virtual Sport data to KPI report
    DB: DB052.bodb_Licensee
	Original :LRF_GET_Licensees_KPIs_2
    Revisions:
            
    Param's Explanation:

*/
SET NOCOUNT ON

declare 
    @FirstDayOfLastThreeMonths datetime,
    @FirstDayOfYear datetime,
    @FromDate datetime,
    @ToDate datetime
	
if (@ReportDate IS NULL)
    select @ToDate = convert(varchar(10), dateadd(dd, -1, current_timestamp), 120)
else
    select @ToDate = convert(varchar(10), @ReportDate, 120)
    
select @FirstDayOfLastThreeMonths = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) - 3, 0) -- First Day of Last Three Months

select @FirstDayOfYear = DATEADD(yy, DATEDIFF(yy,0,@ToDate), 0) -- First Day of Year

if (@FirstDayOfYear > @FirstDayOfLastThreeMonths)
    select @FromDate = @FirstDayOfLastThreeMonths
else
    select @FromDate = @FirstDayOfYear

-- Get result
declare @Sites table(ResellerID int,SiteID int,SiteName varchar(50),DateStarted smalldatetime)
insert into @Sites
    select ResellerID, LabelID,LabelName, '2012-11-01'
    from dbo.view_kpi_labels_VS  (nolock)
	where IsKPIActive = 1
select 
    sites.ResellerID GroupId,
    mtd.siteid SiteID,
    sites.SiteName,
    mtd.rptDate [Date],
    mtd.StatID StatID,
    isnull(
        sum(
            case 
                when mtd.StatID in (14,16) then 0 
                else mtd.MonthToDate 
            end * case when stat.IsCurrency = 1 then EUR else 1 end),0) [Value]
from dbo.rptKPI_MTD_3rdProducts mtd (nolock)
    inner join @Sites sites on mtd.siteid = sites.SiteID
    left join dbo.view_kpi_statistics stat on mtd.StatID = stat.StatID
    left join bodb02.dbo.Lrf_f_GetExchangeDaily(@FromDate,@ToDate) oanda on mtd.rptdate = oanda.exchangedate and mtd.currencyid = oanda.exchangeid
where rptDate between @FromDate and @ToDate
    and (sites.DateStarted is null or rptDate >= sites.DateStarted)
	and mtd.bettype between 1201 AND 1299
group by 
    sites.ResellerID,
    mtd.siteid,
    sites.SiteName,
    mtd.rptDate,
    mtd.StatID
order by sites.ResellerID

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_GET_Licensees_KPIs_VS] TO [bodbLicenseeNet] 
GO
GRANT EXECUTE ON [dbo].[LRF_GET_Licensees_KPIs_VS] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_GET_Licensees_KPIs_VS] TO [VNTeam]
