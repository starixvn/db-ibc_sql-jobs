/*<info serverAlias="DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutCustomerClassUtilityOfferDetail]
    @tvp_param TVP_ReplCustomerClassUtilityOfferDetail READONLY
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
    MERGE [dbo].[CustomerClassUtilityOfferDetail] [t]
    USING @tvp_param [tvp] ON [t].[Currency] = [tvp].[Currency] AND [t].[CustomerClass] = [tvp].[CustomerClass] AND [t].[SiteID] = [tvp].[SiteID] AND [t].[PolicyID] = [tvp].[PolicyID]
    WHEN MATCHED THEN
        UPDATE SET
			[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
            [PolicyID]
            ,[SiteID]
            ,[Currency]
            ,[CustomerClass]
            ,[RepUpdateTime]
			,[isDeleted]
        ) VALUES (
            [tvp].[PolicyID]
            ,[tvp].[SiteID]
            ,[tvp].[Currency]
            ,[tvp].[CustomerClass]
            ,[tvp].[RepUpdateTime]
            ,[tvp].[isDeleted]
        );
END
GO
