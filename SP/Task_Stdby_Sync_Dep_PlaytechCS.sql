/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Stdby_Sync_Dep_PlaytechCS]
	@IsDebug BIT = 0
AS

/*
	Created: 20140529@Don
	Task: PlaytechCS - Sync data
	DB: DBPTCS.bodb_PlaytechCS

	Revisions:
		- 20181102@Daniel: Copy SP to DB052 for sync data from DB053, update server info, change linked server DBPTCS/DBLIC to DB053
		- 20190401@Percy: Add more tables: Product3rd_ImportQueue and LicSystemSetting [RedmineID: #110692]
		- 20190912@Percy: Dynamic query for adapt code between DB052 and DB053 [RedmineID: #120125]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ServCurrent	SYSNAME = ''
	DECLARE @ServRemote		SYSNAME	= ''

	DECLARE @LinkedServer	SYSNAME = ''

	DECLARE @SqlQuery NVARCHAR(1024)

	SELECT  @ServCurrent = @@SERVERNAME

	IF @ServCurrent = 'DB053'
		SELECT @LinkedServer = 'DB052'
	ELSE IF @ServCurrent = 'DB052'
		SELECT @LinkedServer = 'DB053'

	SET @SqlQuery = 'SELECT sn FROM OPENQUERY(' + @LinkedServer + ', ''SELECT @@SERVERNAME sn'')'

	DECLARE @tblServer TABLE (ServerName SYSNAME)
	INSERT INTO @tblServer
	EXEC sp_executesql @SqlQuery

	IF @@ERROR != 0
		RETURN

	SELECT @ServRemote = ServerName FROM @tblServer

	IF ISNULL(@ServCurrent, '') = ISNULL(@ServRemote, '')
		RETURN

	DECLARE @MaxQueueID BIGINT

	-- Product3rd_ImportQueue
	BEGIN
		SELECT @MaxQueueID = MAX(QueueID) FROM dbo.Product3rd_ImportQueue WITH(NOLOCK)
		
		IF @MaxQueueID IS NULL 
			SET @MaxQueueID = 0

		SET @SqlQuery = ''
		
		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(' + @ServRemote + ', ''SELECT TOP (128) QueueID, CheckInTime, LicenseeName, ProductID, CONVERT(NVARCHAR(MAX), XmlData), StartDate, EndDate, JobType
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

	-- Product3rd_ImportQueue_CheckData
	BEGIN
		SELECT @MaxQueueID = NULL
		SELECT @MaxQueueID = MAX(QueueID) FROM dbo.Product3rd_ImportQueue_CheckData WITH(NOLOCK)
		
		IF @MaxQueueID IS NULL 
			SET @MaxQueueID = 0

		SET @SqlQuery = ''
		
		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(' + @ServRemote + ', ''SELECT TOP (128) QueueID, CheckInTime, LicenseeName, ProductID, CONVERT(NVARCHAR(MAX), XmlData)
						FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue_CheckData WITH (NOLOCK)
						WHERE QueueID > ''''' + CAST(@MaxQueueID AS VARCHAR(50)) + '''''
						ORDER BY QueueID
						OPTION (MAXDOP 8)'')'

		IF @IsDebug = 1 
			PRINT @SqlQuery
		ELSE
		BEGIN
			SET IDENTITY_INSERT dbo.Product3rd_ImportQueue_CheckData ON

			INSERT INTO dbo.Product3rd_ImportQueue_CheckData (QueueID, CheckInTime, LicenseeName, ProductID, XmlData)
			EXEC sp_executesql @SqlQuery
			
			SET IDENTITY_INSERT dbo.Product3rd_ImportQueue_CheckData OFF
		END
	END

	-- LicSystemSetting
	BEGIN
		DECLARE @LicSystemSetting TABLE (ID SMALLINT, ProductId SMALLINT, SName VARCHAR(100), SValue VARCHAR(300))
		
		SET @SqlQuery = ''
		
		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(' + @ServRemote + ', ''SELECT ID, ProductId, SName, SValue
						FROM bodb_3rdProduct.dbo.LicSystemSetting WITH (NOLOCK)'')'

		IF @IsDebug = 1 
			PRINT @SqlQuery
		ELSE
		BEGIN
			INSERT INTO @LicSystemSetting (ID, ProductId, SName, SValue)
			EXEC sp_executesql @SqlQuery

			UPDATE l WITH (ROWLOCK, UPDLOCK)
			SET l.SName = t.SName, l.SValue = t.SValue
			FROM bodb_3rdProduct.dbo.LicSystemSetting l
				INNER JOIN @LicSystemSetting t ON l.ID = t.ID
		END
	END
END
GO