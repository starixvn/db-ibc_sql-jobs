 /*<info serverAlias="DBCUST-bodb_Licensee" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[DBA_Lrf_ActiveLicenseeSystem] (
	@LicenseeName VARCHAR(50)
	, @SystemisActive VARCHAR(100) = ''
	, @SystemDeactivate VARCHAR(100) = ''
)
/*  
	Created: 20140502@Jim  
	Task : re-structure create new licensee flow  
	DB: DBCUST-bodb_Licensee
	Original :  
	  
	Revisions:  
	   - 20160912@Jim: add pull service into this flow
	   - 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
	   - 20181129@Amanda: User SP DBA_Lrf_PullServiceSetting to delete pull service [redmine: #83584]
	   
	Param's Explanation:
   
*/
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @tblSystem AS TABLE (
		ID INT IDENTITY(1, 1)
		, SystemId INT
		, SystemCode VARCHAR(10)
		, isActive BIT
		)
	DECLARE @LicenseeId INT

	---   init variable   
	SELECT @LicenseeId = LicenseeId
	FROM dbo.Licensees WITH (NOLOCK)
	WHERE LicenseeName = @LicenseeName

	IF ISNULL(@SystemisActive, '') <> ''
	BEGIN
		INSERT INTO @tblSystem (
			SystemId
			, SystemCode
			, isActive
			)
		SELECT 0
			, val
			, 1
		FROM CUSTDB.dbo.strSplit(@SystemisActive, ',')
	END

	IF ISNULL(@SystemDeactivate, '') <> ''
	BEGIN
		INSERT INTO @tblSystem (
			SystemId
			, SystemCode
			, isActive
			)
		SELECT 0
			, val
			, 0
		FROM CUSTDB.dbo.strSplit(@SystemDeactivate, ',')
	END

	----- Correct Data   
	UPDATE a
	SET SystemId = b.id
	FROM @tblSystem a
	INNER JOIN dbo.Systems b WITH (NOLOCK)
		ON a.SystemCode = b.SystemName

	IF NOT EXISTS (
			SELECT TOP 1 1
			FROM @tblSystem
			WHERE SystemId <> 0
			)
	BEGIN
		RAISERROR ('System is  not correct,please check again', 16, 1)
		RETURN
	END

	--- Set active/deactivate for all of existing systems  
	UPDATE a1
	SET isActive = b1.isActive
	FROM dbo.SystemLicensee a1
	INNER JOIN @tblSystem b1
		ON a1.SystemID = b1.SystemId
	WHERE a1.LicenseeID = @LicenseeId

	DELETE @tblSystem
	WHERE SystemId IN (
			SELECT SystemId
			FROM dbo.SystemLicensee WITH (NOLOCK)
			WHERE LicenseeID = @LicenseeId
			);

	--- Set active/deactivate for all of new systems  
	MERGE dbo.SystemLicensee AS TARGET
	USING (
		SELECT SystemId
			, @LicenseeId AS LicenseeId
			, isActive
		FROM @tblSystem
		) AS SOURCE(SystemId, LicenseeId, isActive)
		ON (
				TARGET.SystemId = SOURCE.SystemId
				AND TARGET.LicenseeId = SOURCE.LicenseeId
				AND TARGET.IsActive = SOURCE.IsActive
				)
	WHEN MATCHED
		THEN
			UPDATE
			SET TARGET.isActive = SOURCE.isActive
	WHEN NOT MATCHED
		THEN
			INSERT (
				SystemId
				, LicenseeId
				, isActive
				)
			VALUES (
				SOURCE.SystemId
				, SOURCE.LicenseeId
				, SOURCE.isActive
				);

	--- deactive pull service 
	IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.SystemLicensee WITH (NOLOCK)
			WHERE LicenseeID = @LicenseeID
				AND IsActive = 0
				AND SystemID = 1
			)
	BEGIN
		EXEC DBPTCS.bodb_PlaytechCS.[dbo].[DBA_Lrf_PullServiceSetting]
					@LicenseeID = @LicenseeId, 
					@LicenseeName = @LicenseeName, 
					@SettingName = 'GoldDeluxe_VersionKey',
					@IsDelete = 1
		EXEC DBPTCS.bodb_PlaytechCS.[dbo].[DBA_Lrf_PullServiceSetting]
					@LicenseeID = @LicenseeId, 
					@LicenseeName = @LicenseeName, 
					@SettingName = 'AGCasino_VersionKey',
					@IsDelete = 1
	END
		--------------------------------------------------------------------
END

GO