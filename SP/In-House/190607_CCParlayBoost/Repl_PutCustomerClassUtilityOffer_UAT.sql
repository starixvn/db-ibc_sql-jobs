/*<info serverAlias="DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutCustomerClassUtilityOffer_UAT]
    @tvp_param TVP_ReplCustomerClassUtilityOffer_UAT READONLY
AS
/*
	Created: 20231002@Winfred
	Task: In-House
	DB: DBTP-bodb02
	
	Revisions:
		- 20231002@Winfred: NAP CM Customer Class - Allow to offer Parlay Boost on rule setting [RedmineID: #190607]
*/
BEGIN
    SET NOCOUNT ON;
	SET IDENTITY_INSERT [dbo].[CustomerClassUtilityOffer_UAT] ON;
    MERGE [dbo].[CustomerClassUtilityOffer_UAT] [t]
    USING @tvp_param [tvp] ON [t].PolicyID = [tvp].PolicyID
    WHEN MATCHED THEN
        UPDATE SET
            [PolicyTitle]  = [tvp].[PolicyTitle]
            ,[UtilityOffering]  = [tvp].[UtilityOffering]
			,[IsTest]        = [tvp].[IsTest]
			,[LastModifiedUser] = [tvp].[LastModifiedUser]
			,[LastModifiedTime] = [tvp].[LastModifiedTime]
			,[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
            [PolicyID]
            ,[PolicyTitle]
            ,[UtilityOffering]
            ,[IsTest]
            ,[LastModifiedUser]
            ,[LastModifiedTime]
            ,[RepUpdateTime]
			,[isDeleted]
        ) VALUES (
            [tvp].[PolicyID]
            ,[tvp].[PolicyTitle]
            ,[tvp].[UtilityOffering]
            ,[tvp].[IsTest]
            ,[tvp].[LastModifiedUser]
            ,[tvp].[LastModifiedTime]
            ,[tvp].[RepUpdateTime]
            ,[tvp].[isDeleted]
        );
	SET IDENTITY_INSERT [dbo].[CustomerClassUtilityOffer_UAT] OFF;
END
GO
