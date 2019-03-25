/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_GenerateNextArchiveDate]
	@TableName varchar(200) = '',
	@Action VARCHAR(20) = 'all'
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

	IF @Action = 'all' AND @TableName = ''
	BEGIN
		DECLARE @__tmpTable TABLE (rowId INT IDENTITY(1,1), tableName VARCHAR(200))
		DECLARE @rowId INT = 1, @tmp_Name VARCHAR(200)

		INSERT INTO @__tmpTable(tableName)
		SELECT DISTINCT TableName
		FROM dbo.Task_ArchiveData_TableList WITH(NOLOCK)

		WHILE EXISTS (SELECT TOP 1 1 FROM @__tmpTable WHERE rowId = @rowId)
		BEGIN
			SELECT @tmp_Name = tableName
			FROM @__tmpTable WHERE rowId = @rowId
			SET @rowId = @rowId + 1

			EXEC dbo.Task_Archive_CustomerLog_GenerateNextArchiveDate @TableName = @tmp_Name, @Action = ''
		END
	END
	ELSE
	BEGIN
		DECLARE @__archiveDatetList TABLE (ArchiveDate DATETIME)
		DECLARE @ArchiveDate DATETIME, @ArchiveDateTo DATETIME, @__temp DATETIME
	
		SELECT @ArchiveDate = ArchiveDate
			, @ArchiveDateTo = DATEADD(DAY, ArchiveDayCount, ArchiveDate)
		FROM dbo.Task_ArchiveData_Setting s WITH(NOLOCK)

		WHILE @ArchiveDate < @ArchiveDateTo
		BEGIN
			SET @ArchiveDate = DATEADD(DAY, 1, @ArchiveDate)
			INSERT INTO @__archiveDatetList(ArchiveDate) VALUES(@ArchiveDate)

		END

		DELETE FROM dbo.Task_ArchiveData_List WHERE TableName = @TableName

		INSERT INTO dbo.Task_ArchiveData_List(TableName, ArchiveDate)
		SELECT @TableName, ArchiveDate
		FROM @__archiveDatetList
	END

END
GO

