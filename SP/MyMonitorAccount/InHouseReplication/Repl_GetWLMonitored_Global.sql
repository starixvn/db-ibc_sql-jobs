/*<info serverAlias="DBCUST-CustDB" executers="repl_ap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Repl_GetWLMonitored_Global]
    @start DATETIME2,
    @count INT,
    @back_fix INT = 0
AS
/*
	Created: 20240415@Eden
	Task: In-House
	DB: DBCUST-CustDB
	
	Revisions:
		- 20240415@Eden: Alpha - Link WL Detail to My Watchlist [RedmineID: #201733]

	Example:
		EXEC [Repl_GetWLMonitored_Global]
			@start = '2024/04/15'
			,@count = 1000
			,@back_fix = 60
			
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @__time_start DATETIME2 = DATEADD(MILLISECOND, -@back_fix, @start);
    DECLARE @__time_end DATETIME2;
    DECLARE @__time_upperbound DATETIME2 = DATEADD(MILLISECOND, -@back_fix, SYSDATETIME());

    SET LOCK_TIMEOUT 1000;

   ; WITH CTE_Timestamp ([RepUpdateTime]) AS (
        SELECT TOP (@count) [RepUpdateTime]
		FROM(
			SELECT [RepUpdateTime]
			FROM [dbo].[WLMonitored_Global] WITH (NOLOCK, INDEX = IX_WLMonitored_Global_RepUpdateTime)
			WHERE [RepUpdateTime] > @start AND [RepUpdateTime] < @__time_upperbound
			UNION ALL 
			SELECT [RepUpdateTime]
			FROM [dbo].WLMonitored_Global_Del WITH (NOLOCK)
			WHERE [RepUpdateTime] > @start AND [RepUpdateTime] < @__time_upperbound	
		) t
		ORDER BY [RepUpdateTime]
    )
    SELECT @__time_end = ISNULL(MAX([RepUpdateTime]), @start) FROM CTE_Timestamp;

    SET LOCK_TIMEOUT -1;

    IF @__time_end > @start
    BEGIN
		;WITH CTE AS(
        SELECT   AgentID
				,Sporttype
				,WinningThreshold
				,WinningUpdateTime
				,LosingThreshold
				,LosingUpdateTime
				,InitSettingTime
				,RepUpdateTime
				,0 AS isDeleted
        FROM [dbo].[WLMonitored_Global]  WITH (NOLOCK, INDEX = IX_WLMonitored_Global_RepUpdateTime)
        WHERE [RepUpdateTime] > @__time_start AND [RepUpdateTime] <= @__time_end
        )
		SELECT   AgentID
				,Sporttype
				,WinningThreshold
				,WinningUpdateTime
				,LosingThreshold
				,LosingUpdateTime
				,InitSettingTime
				,RepUpdateTime
				,0 AS isDeleted
                ,SYSDATETIME() AS [_FetchedTime] 
		FROM CTE
		UNION ALL
		SELECT   AgentID
				,Sporttype
				,WinningThreshold = NULL
				,WinningUpdateTime = NULL
				,LosingThreshold = NULL
				,LosingUpdateTime = NULL
				,InitSettingTime = NULL
				,RepUpdateTime
				,1 AS isDeleted
                ,SYSDATETIME() AS [_FetchedTime]  
		FROM [dbo].WLMonitored_Global_Del del WITH (NOLOCK) 
		WHERE [RepUpdateTime] > @__time_start AND [RepUpdateTime] <= @__time_end 
			AND NOT EXISTS( SELECT TOP 1 1 
							FROM CTE c 
							WHERE c.Sporttype = del.Sporttype AND c.AgentID = del.AgentID
							)
    END;
END
GO
