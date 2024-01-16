/*<info serverAlias="DBCUST-CustDB" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_GetCustomerClassNonSports_UAT]
     @start DATETIME2,
     @count INT,
     @back_fix INT = 0
AS
/*
     Created:  20231002@Winfred
     Task : In-House
     DB: DBCUST-CustDB

     Revisions:
          - 20231002@Winfred: NAP CM Customer Class - Support for Non-Sports [RedmineID: #186116] 
*/
BEGIN
     SET NOCOUNT ON;

     DECLARE @__time_start DATETIME2 = DATEADD(MILLISECOND, -@back_fix, @start);
     DECLARE @__time_end DATETIME2;
     DECLARE @__time_upperbound DATETIME2 = DATEADD(MILLISECOND, -@back_fix, SYSDATETIME());

     SET LOCK_TIMEOUT 1000;


     WITH CTE_Timestamp ([RepUpdateTime]) AS (
          SELECT TOP (@count) [RepUpdateTime]
          FROM [dbo].[CustomerClassNonSports_UAT] WITH (NOLOCK, INDEX = IX_CustomerClassNonSports_UAT_RepUpdateTime)
          WHERE [RepUpdateTime] > @start AND [RepUpdateTime] < @__time_upperbound
          ORDER BY [RepUpdateTime]
     )
     SELECT @__time_end = ISNULL(MAX([RepUpdateTime]), @start) FROM CTE_Timestamp;

     SET LOCK_TIMEOUT -1;

     IF @__time_end > @start
     BEGIN
          SELECT  [PolicyID]
               , [PolicyTitle]
               , [MaxBet]
               , [Products]
               , [Enable]
               , [IsTest]
               , [LastModifiedUser]
               , [LastModifiedTime]
               , [RepUpdateTime]
               , [isDeleted]
               , SYSDATETIME() AS [_FetchedTime]
          FROM [dbo].[CustomerClassNonSports_UAT]  WITH (NOLOCK, INDEX = IX_CustomerClassNonSports_UAT_RepUpdateTime)
          WHERE [RepUpdateTime] > @__time_start AND [RepUpdateTime] <= @__time_end
          ORDER BY [RepUpdateTime];
     END;
END
GO