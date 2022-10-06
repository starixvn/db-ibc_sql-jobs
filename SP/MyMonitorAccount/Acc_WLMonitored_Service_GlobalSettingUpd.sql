/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet,bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_GlobalSettingUpd]
	@ServiceName	VARCHAR(100)
	,@SettingName	VARCHAR(100) 
	,@SettingValue	VARCHAR(100) 
AS
/*	Creator: 20220617@Kathy
	Task: get global setting
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: update global setting [Redmine:#170467]

	Param's Explanation:
		 
*/
BEGIN
	SET NOCOUNT ON

	UPDATE	dbo.WLMonitored_Service_GlobalSetting WITH(ROWLOCK, UPDLOCK)
		SET SettingValue = CASE WHEN SettingName IN ('LastCheckTime', 'LastScanSettingDate') THEN CONVERT(VARCHAR(50), @SettingValue, 121) ELSE @SettingValue END
			,UpdatedTime = GETDATE()
	WHERE	SettingName = @SettingName
			AND ServiceName = @ServiceName
END
GO
