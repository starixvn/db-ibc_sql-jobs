SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROCEDURE [dbo].[DELETED_LRF_GET_Licensees_KPIs_2]
    @ReportDate datetime = NULL
AS
/*
    Created: 20111012@Don
    Task: Implement SP for main KPI report
    DB: DB052.bodb_Licensee

    Revisions:
        - 20120223@Don:
            + Add more six labels into FDL with hard-code for start date
        - 20120307@Don:
            + Adapt for restructuring Licensees and Labels/Sites
        - 20120518@Don: Include SunGame licensee to result
		- 20120518@Jim: add more IsKPIActive  condition 	
		- 20120709@Don: use object view_kpi_labels instead of view_all_labels
		- 20120816@Don: apply oanda exchange rate to resultset
            
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
    select ResellerID, LabelID, LabelName, AffectedDate
    from dbo.view_kpi_labels (nolock)
    where ResellerID <> 3
	    and IsKPIActive = 1
	    
select 
    sites.ResellerID GroupId,
    mtd.siteid SiteID,
    sites.SiteName,
    mtd.rptDate [Date],
    mtd.StatID StatID,
    isnull(
        sum(
            case 
                when mtd.StatID in (15,16) then 0 
                else mtd.MonthToDate 
            end * case when stat.IsCurrency = 1 then EUR else 1 end),0) [Value]
from dbo.rptKPI_MTD_Cross mtd (nolock)
    inner join @Sites sites on mtd.siteid = sites.SiteID
    left join dbo.view_kpi_statistics stat on mtd.StatID = stat.StatID
    left join bodb02.dbo.Lrf_f_GetExchangeDaily(@FromDate,@ToDate) oanda on mtd.rptdate = oanda.exchangedate and mtd.currencyid = oanda.exchangeid
where rptDate between @FromDate and @ToDate
    and (sites.DateStarted is null or rptDate >= sites.DateStarted)
group by 
    sites.ResellerID,
    mtd.siteid,
    sites.SiteName,
    mtd.rptDate,
    mtd.StatID
order by sites.ResellerID

SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[LRF_GET_Licensees_KPIs_2] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_GET_Licensees_KPIs_2] TO [VNTeam]
