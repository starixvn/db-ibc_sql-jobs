USE [bodb_LicenseeReport]
GO
CREATE OR ALTER PROCEDURE [dbo].[Task_Maintainance_LicenseeReport_Update]
	@TableName VARCHAR(128) = NULL,
	@Action VARCHAR(100) = 'REORGANIZE'
AS
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - Index maintainance
	DB: DBEXT.bodb02

	Revisions:
		- 20230209@Bobby: Created [RedmineID: #172604]
		
*/
BEGIN  
	SET NOCOUNT ON;
	-- TODO: REBUILD Partition
	-- ALTER INDEX index_name ON schema_name.table_name REBUILD PARTITION = 2 WITH(ONLINE=ON);

	IF (@Action NOT IN ('REORGANIZE', 'REBUILD')) RETURN;

	DROP TABLE IF EXISTS #tmpIndex;
	CREATE TABLE #tmpIndex (idx INT IDENTITY(1, 1), table_name VARCHAR(128), index_name VARCHAR(128), partition_number INT, [schema_id] INT);

	INSERT INTO #tmpIndex (table_name, index_name, partition_number, [schema_id])
	SELECT DISTINCT OBJECT_NAME(i.object_id) AS table_name, i.name AS index_name, p.partition_number, o.[schema_id]
	FROM sys.indexes i
		INNER JOIN sys.objects o ON o.object_id = i.object_id
		INNER JOIN sys.partitions p on p.object_id = i.object_id and p.index_id = i.index_id
		INNER JOIN sys.column_store_row_groups rg ON rg.object_id = p.object_id AND rg.index_id = p.index_id AND rg.partition_number = p.partition_number
	WHERE (@TableName IS NULL OR OBJECT_NAME(i.object_id) = @TableName)
		AND 1 = CASE 
					WHEN @Action='REORGANIZE' AND (rg.delta_store_hobt_id > 0 OR rg.deleted_rows > 0) THEN 1
					WHEN @Action='REBUILD' THEN 1
					ELSE 0
				END


	DECLARE @rIdx INT = 1,
		@table_name VARCHAR(128),
		@index_name VARCHAR(128),
		@partition_number INT, @schema_id INT,
		@cmdRun NVARCHAR(MAX);

	WHILE EXISTS (SELECT 1 FROM #tmpIndex WHERE idx = @rIdx)
	BEGIN
		
		SELECT @table_name		= table_name,
			@index_name			= index_name,
			@partition_number	= partition_number,
			@schema_id			= [schema_id]
		FROM #tmpIndex WHERE idx = @rIdx

		SELECT @cmdRun = t.Command
		FROM (
			SELECT 'REBUILD', CONCAT('ALTER INDEX ', @index_name, ' ON ',SCHEMA_NAME(@schema_id),'.', @table_name, ' REBUILD PARTITION=', @partition_number-1, ' WITH(ONLINE = ON);')
			UNION ALL
			SELECT 'REORGANIZE', CONCAT('ALTER INDEX ', @index_name, ' ON ',SCHEMA_NAME(@schema_id),'.', @table_name, ' REORGANIZE PARTITION=', @partition_number, ' WITH(COMPRESS_ALL_ROW_GROUPS = ON);')
		) AS t (ActionRun, Command)
		WHERE t.ActionRun = @Action

		SELECT @cmdRun

		EXEC (@cmdRun);

		SET @rIdx += 1;
	END

END 
GO
