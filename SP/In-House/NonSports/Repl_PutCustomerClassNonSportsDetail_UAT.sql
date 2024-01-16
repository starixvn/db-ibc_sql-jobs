/*<info serverAlias="DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_PutCustomerClassNonSportsDetail_UAT]
     @tvp_param TVP_ReplCustomerClassNonSportsDetail_UAT READONLY
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

     MERGE [dbo].[CustomerClassNonSportsDetail_UAT] [t]
     USING @tvp_param [tvp] ON [t].[CustomerClass] = [tvp].[CustomerClass] AND [t].[SiteID] = [tvp].[SiteID] AND [t].[PolicyID] = [tvp].[PolicyID]
     WHEN MATCHED THEN 
        UPDATE SET 
           [isDeleted]  = [tvp].[isDeleted]
        , [RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
     WHEN NOT MATCHED THEN 
        INSERT ( 
               [PolicyID]
               , [SiteID]
               , [CustomerClass]
               , [RepUpdateTime]
               , [isDeleted]
               ) VALUES ( 
               [tvp].[PolicyID]
               , [tvp].[SiteID]
               , [tvp].[CustomerClass]
               , [tvp].[RepUpdateTime]
               , [tvp].[isDeleted]
               );
END
GO