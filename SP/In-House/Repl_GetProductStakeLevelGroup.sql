/*<info serverAlias="DBCUST-CustDB" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_GetProductStakeLevelGroup]
    @start DATETIME2,
    @count INT,
    @back_fix INT = 0
AS
/*
    Created: 20230912@Tacy
	Task : 3rd Products - Simplify RNG Games bet limit setting
	DB: DBCUST-CustDB
	
	Revisions:
		- 20230912@Tacy: Create SP for in-house replication use [Redmine:#194332]
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @__time_start DATETIME2 = DATEADD(MILLISECOND, -@back_fix, @start);
    DECLARE @__time_end DATETIME2;
    DECLARE @__time_upperbound DATETIME2 = DATEADD(MILLISECOND, -@back_fix, SYSDATETIME());

    SET LOCK_TIMEOUT 1000;

    WITH CTE_Timestamp ([RepUpdateTime]) AS (
        SELECT TOP (@count) [RepUpdateTime]
        FROM [dbo].[ProductStakeLevelGroup] WITH (NOLOCK, INDEX = IX_ProductStakeLevelGroup_RepUpdateTime)
        WHERE [RepUpdateTime] > @start AND [RepUpdateTime] < @__time_upperbound
        ORDER BY [RepUpdateTime]
    )
    SELECT @__time_end = ISNULL(MAX([RepUpdateTime]), @start) FROM CTE_Timestamp;

    SET LOCK_TIMEOUT -1;

    IF @__time_end > @start
    BEGIN
        SELECT [Sporttype]
                ,[GameGroupID]
                ,[MinBet]
                ,[MaxBet]
                ,[CreditGroupID]
				,[Remark]
                ,[RepUpdateTime]
				,[isDeleted]
                ,SYSDATETIME() AS [_FetchedTime]
        FROM [dbo].[ProductStakeLevelGroup]  WITH (NOLOCK, INDEX = IX_ProductStakeLevelGroup_RepUpdateTime)
        WHERE [RepUpdateTime] > @__time_start AND [RepUpdateTime] <= @__time_end
        ORDER BY [RepUpdateTime];
    END;
END
GO