/*<info serverAlias="DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutDep_CustBonusSharing]
    @tvp_param TVP_ReplDep_CustBonusSharing READONLY
AS
/*
	Created: 20230906@Tacy
	Task: In-House
	DB: DBTP-bodb02
	
	Revisions:
		- 20230906@Tacy: Integration - Parlay Boost Bonus [RedmineID: #186192]
*/
BEGIN
    SET NOCOUNT ON;
    MERGE [dbo].[Dep_CustBonusSharing] [t]
    USING @tvp_param [tvp] ON [t].[CustID] = [tvp].[CustID]
                            AND [t].[FromDate] = [tvp].[FromDate]
    WHEN MATCHED THEN
        UPDATE SET
            [BonusSharingRate]  = [tvp].[BonusSharingRate]
            ,[ToDate]           = [tvp].[ToDate]
			,[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
            [CustID]
            ,[BonusSharingRate]
            ,[FromDate]
            ,[ToDate]
            ,[RepUpdateTime]
			,[isDeleted]
        ) VALUES (
            [tvp].[CustID]
            ,[tvp].[BonusSharingRate]
            ,[tvp].[FromDate]
            ,[tvp].[ToDate]
            ,[tvp].[RepUpdateTime]
            ,[tvp].[isDeleted]
        );
END
GO