/*<info serverAlias="DBACC-bodb02,DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutProductStakeLevelGroup]
    @tvp_param TVP_ReplProductStakeLevelGroup READONLY
AS
/*
    Created: 20230912@Tacy
	Task : 3rd Products - Simplify RNG Games bet limit setting
	DB: DBACC-bodb02,DBTP-bodb02
	
	Revisions:
		- 20230912@Tacy: Create SP for in-house replication use [Redmine:#192624]
*/
BEGIN
    SET NOCOUNT ON;
    MERGE [dbo].[ProductStakeLevelGroup] [t]
    USING @tvp_param [tvp] ON [t].[Sporttype] = [tvp].[Sporttype]
                            AND [t].[GameGroupID] = [tvp].[GameGroupID]
                            AND [t].[CreditGroupID] = [tvp].[CreditGroupID]
    WHEN MATCHED THEN
        UPDATE SET
            [MinBet]			= [tvp].[MinBet]
            ,[MaxBet]           = [tvp].[MaxBet]
            ,[Remark]           = [tvp].[Remark]
            ,[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
            [Sporttype]
            ,[GameGroupID]
            ,[MinBet]
            ,[MaxBet]
            ,[CreditGroupID]
			,[Remark]
            ,[RepUpdateTime]
			,[isDeleted]
        ) VALUES (
			[tvp].[Sporttype]
            ,[tvp].[GameGroupID]
            ,[tvp].[MinBet]
            ,[tvp].[MaxBet]
            ,[tvp].[CreditGroupID]
			,[tvp].[Remark]
            ,[tvp].[RepUpdateTime]
			,[tvp].[isDeleted]
        );
END
GO
