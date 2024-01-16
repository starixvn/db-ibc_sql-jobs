/*<info serverAlias="DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_PutCustomerClassNonSports]
     @tvp_param TVP_ReplCustomerClassNonSports READONLY
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
     SET IDENTITY_INSERT [dbo].[CustomerClassNonSports] ON;

     MERGE [dbo].[CustomerClassNonSports] [t]
     USING @tvp_param [tvp] ON [t].[PolicyID] = [tvp].[PolicyID]
     WHEN MATCHED THEN 
        UPDATE SET 
          [PolicyTitle]  = [tvp].[PolicyTitle]
        , [MaxBet]  = [tvp].[MaxBet]
        , [Products]  = [tvp].[Products]
        , [Enable]  = [tvp].[Enable]
        , [IsTest]  = [tvp].[IsTest]
        , [LastModifiedUser]  = [tvp].[LastModifiedUser]
        , [LastModifiedTime]  = [tvp].[LastModifiedTime]
        , [isDeleted]  = [tvp].[isDeleted]
        , [RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
     WHEN NOT MATCHED THEN 
        INSERT ( 
               [PolicyID]
               , [PolicyTitle]
               , [MaxBet]
               , [Products]
               , [Enable]
               , [IsTest]
               , [LastModifiedUser]
               , [LastModifiedTime]
               , [RepUpdateTime]
               , [isDeleted]
               ) VALUES ( 
               [tvp].[PolicyID]
               , [tvp].[PolicyTitle]
               , [tvp].[MaxBet]
               , [tvp].[Products]
               , [tvp].[Enable]
               , [tvp].[IsTest]
               , [tvp].[LastModifiedUser]
               , [tvp].[LastModifiedTime]
               , [tvp].[RepUpdateTime]
               , [tvp].[isDeleted]
               );
     SET IDENTITY_INSERT [dbo].[CustomerClassNonSports] OFF;
END
GO