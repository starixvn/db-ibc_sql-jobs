USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Stdby_Sync_Dep_PlaytechCS] @IsDebug BIT = 0
AS
/*
Created	: 20140529@Don
Task	: PlaytechCS - Sync data 
DB		: DB052.bodb_PlaytechCS

Revisions:
	20181102@Daniel: Copy SP to DB052 for sync data from DB053, update server info, change linked server DBPTCS/DBLIC to DB053
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @ServCurrent SYSNAME = ''
	DECLARE @ServRemote SYSNAME	= ''
 
	SELECT @ServCurrent = @@SERVERNAME
	SELECT @ServRemote  = (SELECT sn FROM OPENQUERY(DB053,'SELECT @@SERVERNAME sn'))

	IF @@ERROR != 0
		RETURN

	IF ISNULL(@ServCurrent, '') = ISNULL(@ServRemote, '')
		RETURN

	DECLARE @SqlQuery NVARCHAR(1024)

	--BEGIN --LicIntegrationSetting

	--	CREATE TABLE #TmpData([LicenseeID] INT, [LicenseeName] VARCHAR(50), [SettingName] VARCHAR(50), [SettingValue] VARCHAR(200), [AllowApiBalance] BIT)

	--	SET @SqlQuery = ''
	--	SET @SqlQuery = 'SELECT *
	--					FROM OPENQUERY(DBPTCS, ''SELECT LicenseeID, LicenseeName, SettingName, SettingValue, AllowApiBalance
	--					FROM bodb_PlaytechCS.dbo.LicIntegrationSetting WITH (NOLOCK)
	--					OPTION (MAXDOP 8)'')'

	--	IF @IsDebug = 1 
	--		PRINT @SqlQuery
	--	ELSE
	--	BEGIN
	--		INSERT INTO #TmpData(LicenseeID, LicenseeName, SettingName, SettingValue, AllowApiBalance)
	--		EXEC sp_executesql @SqlQuery

	--		MERGE dbo.LicIntegrationSetting t
	--		USING #TmpData s ON t.LicenseeId = s.LicenseeId AND t.SettingName = s.SettingName
	--		WHEN MATCHED THEN 
	--			UPDATE SET LicenseeName = s.LicenseeName, SettingValue = s.SettingValue, AllowApiBalance = s.AllowApiBalance
	--		WHEN NOT MATCHED BY TARGET THEN
	--			INSERT (LicenseeID, LicenseeName, SettingName, SettingValue, AllowApiBalance)
	--			VALUES(s.LicenseeID, s.LicenseeName, s.SettingName, s.SettingValue, s.AllowApiBalance) 
	--		WHEN NOT MATCHED BY SOURCE THEN
	--			DELETE;
	--	END
	--END

	BEGIN --Product3rd_ImportQueue

	DECLARE @MaxQueueID BIGINT
	SELECT @MaxQueueID = MAX(QueueID) FROM dbo.Product3rd_ImportQueue WITH(NOLOCK)
	IF @MaxQueueID IS NULL 
		SET @MaxQueueID = 0

	SET @SqlQuery = ''
		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(DB053, ''SELECT TOP (128) QueueID, CheckInTime, LicenseeName, ProductID, CONVERT(NVARCHAR(MAX), XmlData), StartDate, EndDate, JobType
						FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
						WHERE QueueID > ''''' + CAST(@MaxQueueID AS VARCHAR(50)) + '''''
						ORDER BY QueueID
						OPTION (MAXDOP 8)'')'

		IF @IsDebug = 1 
			PRINT @SqlQuery
		ELSE
		BEGIN
			SET IDENTITY_INSERT dbo.Product3rd_ImportQueue ON

			INSERT INTO dbo.Product3rd_ImportQueue(QueueID, CheckInTime, LicenseeName, ProductID, XmlData, StartDate, EndDate, JobType)
			EXEC sp_executesql @SqlQuery
			SET IDENTITY_INSERT dbo.Product3rd_ImportQueue OFF

		END
	END

	--BEGIN--Product3rd_ImportQueue_bk
	
	--	DECLARE @MaxQueueID2 BIGINT
	--	SELECT @MaxQueueID2 = MAX(QueueID) FROM dbo.Product3rd_ImportQueue_bk WITH(NOLOCK)
	--	IF @MaxQueueID2 IS NULL 
	--		SET @MaxQueueID2 = 0

	--	SET IDENTITY_INSERT dbo.Product3rd_ImportQueue_bk ON

	--	INSERT INTO dbo.Product3rd_ImportQueue_bk(QueueID, CheckInTime, LicenseeName, ProductID, XmlData)
	--	SELECT TOP(128) QueueID, CheckInTime, LicenseeName, ProductID, XmlData
	--	FROM dbo.Product3rd_ImportQueue WITH(NOLOCK)
	--	WHERE QueueID > @MaxQueueID2
	--	ORDER BY QueueID

	--	SET IDENTITY_INSERT dbo.Product3rd_ImportQueue_bk OFF
	--END
END
GO