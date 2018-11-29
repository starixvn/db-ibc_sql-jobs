/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[DBA_Lrf_PullServiceSetting]
	@LicenseeId		INT,
	@LicenseeName	VARCHAR(50),
	@SettingName	VARCHAR(50), --'AGCasino_VersionKey/GoldDeluxe_VersionKey'
	@IsDelete		BIT = 0
AS
/*
	 Created: Amanda
	 Date: 2018-11-26
	 Task: Implement "Licensee Setting" function
	 DB: DBPTCS-bodb_PlaytechCS
	 
	 Revisions:
	  - 20181126@Amanda: Add/Remove pull service setting [Redmine: #83584]
*/
BEGIN
	SET NOCOUNT ON

	IF @IsDelete = 1
	BEGIN
		DELETE dbo.LicIntegrationSetting WITH (ROWLOCK) WHERE LicenseeId = @LicenseeId AND LicenseeName = @LicenseeName AND SettingName = @SettingName
		RETURN 
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.LicIntegrationSetting WHERE LicenseeID = @LicenseeID AND SettingName = @SettingName)
	BEGIN
		INSERT INTO dbo.LicIntegrationSetting (LicenseeID, LicenseeName, SettingName, SettingValue, AllowApiBalance)
		SELECT @LicenseeID, @LicenseeName, @SettingName, 0,0
	END
	
END