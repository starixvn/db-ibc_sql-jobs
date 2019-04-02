USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Stdby_Sync_Dep_PlaytechCS]
	@IsDebug BIT = 0
AS

/*
	Created	: 20140529@Don
	Task	: PlaytechCS - Sync data 
	DB		: DB052.bodb_PlaytechCS

	Revisions:
		- 20181102@Daniel: Copy SP to DB052 for sync data from DB053, update server info, change linked server DBPTCS/DBLIC to DB053
		- 20190401@Percy: Add more tables: Product3rd_ImportQueue and LicSystemSetting [RedmineID: #110692]
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

	DECLARE @MaxQueueID BIGINT

	-- Product3rd_ImportQueue
	BEGIN
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

	-- Product3rd_ImportQueue_CheckData
	BEGIN
		SELECT @MaxQueueID = NULL
		SELECT @MaxQueueID = MAX(QueueID) FROM dbo.Product3rd_ImportQueue_CheckData WITH(NOLOCK)
		
		IF @MaxQueueID IS NULL 
			SET @MaxQueueID = 0

		SET @SqlQuery = ''
		
		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(DB053, ''SELECT TOP (128) QueueID, CheckInTime, LicenseeName, ProductID, CONVERT(NVARCHAR(MAX), XmlData)
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
						FROM OPENQUERY(DB053, ''SELECT ID, ProductId, SName, SValue
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