/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[DBA_lrf_EnableService]
	@LicenseeId		INT,
	@LicenseeName	VARCHAR(50),
	@SettingName	VARCHAR(50) --'AGCasino_VersionKey/GoldDeluxe_VersionKey'
AS
/*
	 Created: Amanda
	 Date: 2018-11-26
	 Task: Implement "Licensee Setting" function
	 DB: DBPTCS-bodb_PlaytechCS
	 
	 Revisions:
	  - 20181126@Amanda: SP to add pull service setting [Redmine: #83584]
*/
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.LicIntegrationSetting WHERE LicenseeID = @LicenseeID AND SettingName = @SettingName)
	BEGIN
		INSERT INTO dbo.LicIntegrationSetting (LicenseeID, LicenseeName, SettingName, SettingValue, AllowApiBalance)
		SELECT @LicenseeID, @LicenseeName, @SettingName, 0,0
	END
	
END