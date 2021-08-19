SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DELETED_LRF_Get_BudgetByPeriod_KPIs]
    @ReportDate smalldatetime
    ,@TimeType smallint
AS
/*
    Created: 20111012@Don
    Task: 
    DB: DB052.bodb_Licensee

    Revisions:
        
    Param's Explanation:
        @TimeType:
            1: Budgets for last month, 2: budgets for current month, 3: cumulative budgets to last month
*/
SET NOCOUNT ON

-- Date
DECLARE 
    @InputDate smalldatetime
    ,@Date_FirstDayOfYear smalldatetime
    ,@Date_FirstDayOfCurrentMonth smalldatetime
    ,@Date_FirstDayOfNextMonth smalldatetime
    ,@Date_FirstDayOfLastMonth smalldatetime

SELECT @InputDate = @ReportDate

IF @InputDate IS NULL
    SELECT @InputDate = CONVERT(varchar(10), DATEADD(DAY, -1, GETDATE()), 120)
ELSE
    SELECT @InputDate = CONVERT(varchar(10), @InputDate, 120)

SELECT 
    @Date_FirstDayOfYear = DATEADD(yy, DATEDIFF(yy,0,@InputDate), 0)
    ,@Date_FirstDayOfCurrentMonth = DATEADD(MONTH, DATEDIFF(MONTH,0,@InputDate), 0)    
    ,@Date_FirstDayOfLastMonth = DATEADD(MONTH, DATEDIFF(MONTH,0,@InputDate) - 1, 0)
    ,@Date_FirstDayOfNextMonth = DATEADD(MONTH, 1, @Date_FirstDayOfCurrentMonth);



-- Result
WITH Budgets AS
    (
    SELECT [Date], GroupID, StatID, BudgetAmount
    FROM dbo.tblKPI_Budgets (NOLOCK)
    WHERE [Date] >= @Date_FirstDayOfYear AND [Date] < @Date_FirstDayOfNextMonth
    )

SELECT [Date], GroupID, StatID, BudgetAmount
FROM Budgets
WHERE [Date] = @Date_FirstDayOfLastMonth AND @TimeType = 1
    
UNION ALL
SELECT [Date], GroupID, StatID, BudgetAmount
FROM Budgets
WHERE [Date] = @Date_FirstDayOfCurrentMonth AND @TimeType = 2

UNION ALL
SELECT @Date_FirstDayOfLastMonth [Date], b.GroupID, b.StatID, ISNULL(SUM(b.BudgetAmount),0) BudgetAmount
FROM Budgets b
WHERE 
    b.[Date] <= @Date_FirstDayOfLastMonth
    AND @TimeType = 3
GROUP BY b.GroupID, b.StatID

SET NOCOUNT OFF



GO
GRANT EXECUTE ON [dbo].[LRF_Get_BudgetByPeriod_KPIs] TO [bodbLicenseeNet]    
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_BudgetByPeriod_KPIs] TO [VNTeam]