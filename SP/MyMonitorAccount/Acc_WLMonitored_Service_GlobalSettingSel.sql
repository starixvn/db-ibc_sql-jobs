/*<info serverAlias="DBAGE-bodb02, DBEXT-bodb02" executers="bodbDownlineNet,bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_GlobalSettingSel]
	@ServiceName	VARCHAR(100) = NULL
AS
/*	Creator: 20220617@Kathy
	Task: get global setting
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: get global setting [Redmine:#170467]

	Param's Explanation:
		 
*/
BEGIN
	SET NOCOUNT ON
	IF ISNULL(@ServiceName,'') <> ''
		SELECT	ServiceName, SettingName, SettingValue
		FROM	dbo.WLMonitored_Service_GlobalSetting WITH(NOLOCK)
		WHERE	ServiceName = @ServiceName
	ELSE
		SELECT	ServiceName, SettingName, SettingValue
		FROM	dbo.WLMonitored_Service_GlobalSetting WITH(NOLOCK)
END
GO
