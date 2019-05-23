/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_Delete_PreCheck]
AS
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190227@Patrick: Initalize [RedmineId: #110208] 	
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT TOP 1 1 
		FROM dbo.Task_ArchiveData_List_Processing WITH(NOLOCK)
	)
	BEGIN
		PRINT 'Job copy data not done yet. Please check!!!'
		RAISERROR('Job copy data not done yet. Please check!!!', 16, 1)
		RETURN
	END

	--//check rowcount
	DECLARE @__tableList TABLE (rowId INT IDENTITY(1,1), tableName VARCHAR(128))
	INSERT INTO @__tableList(tableName)
	SELECT TableName FROM dbo.Task_ArchiveData_TableList

	DECLARE @rowId INT, @tableName VARCHAR(200), @sqlCmdS NVARCHAR(3000)
		, @sqlCmdT NVARCHAR(3000), @sourceRowCount INT, @targetRowCount INT
		, @dateFrom DATETIME, @dateTo DATETIME, @sqlCmdTemp NVARCHAR(3000)

	SELECT @rowId = 1
		, @sqlCmdS = 'SELECT @sourceRowCount = COUNT(1) 
						FROM dbo.{{TableName}} WHERE logdate >= @dateFrom AND logdate < DATEADD(DAY, 1, @dateTo)'
		, @sqlCmdT = 'SELECT @targetRowCount = COUNT(1) 
						FROM bodb_CustomerLog_Archive.dbo.{{TableName}} WHERE logdate >= @dateFrom AND logdate < DATEADD(DAY, 1, @dateTo)'
		, @dateFrom = MIN(archiveDate)
		, @dateTo = MAX(archiveDate)
	FROM dbo.Task_ArchiveData_List

	DECLARE @__result TABLE(tableName VARCHAR(200), sourceRowCount INT, targetRowCount INT)

	WHILE EXISTS (SELECT TOP 1 1 FROM @__tableList WHERE rowId = @rowId)
	BEGIN
		SELECT @tableName = tableName FROM @__tableList WHERE rowId = @rowId
		SET @rowId = @rowId + 1

		SET @sqlCmdTemp = REPLACE(@sqlCmdS, '{{TableName}}', @tableName)
		--PRINT @sqlCmdTemp
		EXEC sp_executesql @sqlCmdTemp
			, N'@sourceRowCount INT OUTPUT, @dateFrom DATETIME, @dateTo DATETIME'
			, @sourceRowCount = @sourceRowCount OUTPUT, @dateFrom = @dateFrom, @dateTo = @dateTo

		SET @sqlCmdTemp = REPLACE(@sqlCmdT, '{{TableName}}', @tableName)
		--PRINT @sqlCmdTemp
		EXEC sp_executesql @sqlCmdTemp
			, N'@targetRowCount INT OUTPUT, @dateFrom DATETIME, @dateTo DATETIME'
			, @targetRowCount = @targetRowCount OUTPUT, @dateFrom = @dateFrom, @dateTo = @dateTo

		INSERT INTO @__result(tableName, sourceRowCount, targetRowCount)
		VALUES(@tableName, @sourceRowCount, @targetRowCount)

	END

	--check result
	DECLARE @strResult XML
	IF EXISTS (SELECT TOP 1 1 FROM @__result WHERE sourceRowCount <> targetRowCount)
	BEGIN
		SET @strResult = (SELECT * FROM @__result FOR XML RAW ('CheckRowCount'))
		PRINT CAST(@strResult AS NVARCHAR(MAX))
		RAISERROR('Having data mismatch for archiving bodb_CustomerLog. Please take a look.', 16, 1)
		RETURN
	END
END
GO