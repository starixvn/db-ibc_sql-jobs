/*<info serverAlias="DBTP-bodb02,DBAGE-bodb02, DBTXN-CustDB" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutDep_ChargeInfoSetting]
    @tvp_param TVP_ReplDep_ChargeInfoSetting READONLY
AS
/*
    Created: 20240228@Tacy
	Task : In-House
	DB: DBTP-bodb02,DBAGE-bodb02, DBTXN-CustDB
	
	Revisions:
		- 20240228@Tacy: Create SP [Redmine:#201169]
*/
BEGIN
    SET NOCOUNT ON;

	SET IDENTITY_INSERT [dbo].[Dep_ChargeInfoSetting] ON;

    MERGE [dbo].[Dep_ChargeInfoSetting] [t]
    USING @tvp_param [tvp] ON [t].[ChargeId] = [tvp].[ChargeId]
    WHEN MATCHED THEN
        UPDATE SET
			[CustID]			=[tvp].[CustID]
			,[SportType]		=[tvp].[SportType]
			,[PT]				=[tvp].[PT]
			,[FromDate]			=[tvp].[FromDate]
			,[ToDate]			=[tvp].[ToDate]
			,[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
             [ChargeId]
			,[CustID]
			,[SportType]
			,[PT]
			,[FromDate]
			,[ToDate]
			,[isDeleted]
			,[RepUpdateTime]
        ) VALUES (
			 [tvp].[ChargeId]
			,[tvp].[CustID]
			,[tvp].[SportType]
			,[tvp].[PT]
			,[tvp].[FromDate]
			,[tvp].[ToDate]
			,[tvp].[isDeleted]
			,[tvp].[RepUpdateTime]
        );

	SET IDENTITY_INSERT [dbo].[Dep_ChargeInfoSetting] OFF;
END
GO
