USE [bodb_Archive]
GO

/****** Object:  StoredProcedure [dbo].[DBA_CloneTableStructure]    Script Date: 01/27/2015 04:14:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DBA_CloneTableStructure]
    @SourceSchema nvarchar(255),
    @SourceTable nvarchar(255),
    @DestinationSchema nvarchar(255) = '',
    @DestinationTable nvarchar(255),
    @RecreateIfExists bit = 0,
	@FileGroup varchar(1000) = ''
AS
/*
	Created by: Francis
	CreatedDate: 2014-12-11
	Task: Clone a table and create its primary key, all indexes and optionally move it to new filegroup
	DB: DBTP.bodb_Archive
    Revision:
       
    Param's Explanation:
    - @RecreateIfExists: Drop then recreate the destination table if exists
    - @FileGroup: The file group the new crated table will be moved to, default: PRIMARY file group
       
    Notes:
    Which are copied:
    * Table's Structure
    * Primary key
    * Indexes (including ASC/DESC, included columns, filters)
    * Constraints (and unique constraints)        
*/
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION
	BEGIN TRY

		IF @DestinationSchema = ''
			SET @DestinationSchema = @SourceSchema
		IF @FileGroup = ''
			SET @FileGroup = 'PRIMARY'

    --drop the table
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @DestinationSchema AND TABLE_NAME = @DestinationTable)
		BEGIN
			IF @RecreateIfExists = 1
			BEGIN
				EXEC('DROP TABLE [' + @DestinationSchema + '].[' + @DestinationTable + ']')
			END
			ELSE
				RETURN
		END

		--create the table
		EXEC('SELECT TOP (0) * INTO [' + @DestinationSchema + '].[' + @DestinationTable + '] FROM [' + @SourceSchema + '].[' + @SourceTable + ']')

		DECLARE @PKSchema nvarchar(255), @PKName nvarchar(255)
		SELECT TOP 1 @PKSchema = CONSTRAINT_SCHEMA, @PKName = CONSTRAINT_NAME 
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
		WHERE TABLE_SCHEMA = @SourceSchema AND TABLE_NAME = @SourceTable AND CONSTRAINT_TYPE = 'PRIMARY KEY'

			--create primary key
		IF NOT @PKSchema IS NULL AND NOT @PKName IS NULL
		BEGIN
			DECLARE @PKColumns nvarchar(MAX)
			SET @PKColumns = ''

			SELECT @PKColumns = @PKColumns + '[' + COLUMN_NAME + '],'
			FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
			WHERE TABLE_NAME = @SourceTable AND TABLE_SCHEMA = @SourceSchema 
				  AND CONSTRAINT_SCHEMA = @PKSchema AND CONSTRAINT_NAME= @PKName
			ORDER BY ORDINAL_POSITION

			SET @PKColumns = LEFT(@PKColumns, LEN(@PKColumns) - 1)

			EXEC('ALTER TABLE [' + @DestinationSchema + '].[' + @DestinationTable + '] ADD  CONSTRAINT [PK_' + @DestinationTable + '] PRIMARY KEY CLUSTERED (' + @PKColumns + ')');
		END

		--create other indexes
		DECLARE @IndexId int, @IndexName nvarchar(255), @IsUnique bit, 
				@IsUniqueConstraint bit, @FilterDefinition nvarchar(max)
		DECLARE @IndexType int

		DECLARE indexcursor CURSOR FOR
			SELECT index_id, [type], name, is_unique, is_unique_constraint, filter_definition 
			FROM sys.indexes 
			WHERE object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']') and [type] IN (1,2)
		OPEN indexcursor;
		FETCH NEXT FROM indexcursor 
			INTO @IndexId, @IndexType, @IndexName, @IsUnique, @IsUniqueConstraint, @FilterDefinition;
		WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @Unique NVARCHAR(255)
				SET @Unique = CASE WHEN @IsUnique = 1 THEN ' UNIQUE ' ELSE '' END

				DECLARE @KeyColumns NVARCHAR(MAX), @IncludedColumns NVARCHAR(MAX)
				SET @KeyColumns = ''
				SET @IncludedColumns = ''

				SELECT @KeyColumns = @KeyColumns + '[' + c.name + '] ' + CASE WHEN is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END + ',' 
				FROM sys.index_columns ic
					INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
				WHERE index_id = @IndexId and ic.object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']') and key_ordinal > 0
				ORDER BY key_ordinal ASC

				SELECT @IncludedColumns = @IncludedColumns + '[' + c.name + '],' FROM sys.index_columns ic
					INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
				WHERE index_id = @IndexId and ic.object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']') and is_included_column = 1
					
				IF LEN(@KeyColumns) > 0
					SET @KeyColumns = LEFT(@KeyColumns, LEN(@KeyColumns) - 1)

				IF LEN(@IncludedColumns) > 0
					SET @IncludedColumns = ' INCLUDE (' + LEFT(@IncludedColumns, LEN(@IncludedColumns) - 1) + ')'
					
				IF @FilterDefinition IS NULL
					SET @FilterDefinition = ''
				ELSE
					SET @FilterDefinition = 'WHERE ' + @FilterDefinition + ' '
				
				--Non-clustered index
				IF @IsUniqueConstraint = 0 AND @IndexType = 2
					EXEC('CREATE ' + @Unique + ' NONCLUSTERED INDEX [' + @IndexName + '] ON [' + @DestinationSchema + '].[' + @DestinationTable + '] (' + @KeyColumns + ')' + @IncludedColumns + @FilterDefinition + ' ON ' + @FileGroup + ' ')
				IF @IsUniqueConstraint = 1
					BEGIN
						SET @IndexName = REPLACE(@IndexName, @SourceTable, @DestinationTable)
						EXEC('ALTER TABLE [' + @DestinationSchema + '].[' + @DestinationTable + '] ADD  CONSTRAINT [' + @IndexName + '] UNIQUE NONCLUSTERED (' + @KeyColumns + ')');
					END

				--Clustered index
				IF @IsUniqueConstraint = 0 AND @IndexType = 1
					EXEC('CREATE ' + @Unique + ' CLUSTERED INDEX [' + @IndexName + '] ON [' + @DestinationSchema + '].[' + @DestinationTable + '] (' + @KeyColumns + ') ON ' + @FileGroup + ' ')

				FETCH NEXT FROM indexcursor INTO @IndexId, @IndexType, @IndexName, @IsUnique, @IsUniqueConstraint, @FilterDefinition;
			END;
		CLOSE indexcursor;
		DEALLOCATE indexcursor;

		--create constraints
		DECLARE @ConstraintName nvarchar(max), @CheckClause nvarchar(max)
		DECLARE constraintcursor CURSOR FOR
		SELECT REPLACE(c.CONSTRAINT_NAME, @SourceTable, @DestinationTable), CHECK_CLAUSE from INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE t
			INNER JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS c ON c.CONSTRAINT_SCHEMA = TABLE_SCHEMA AND c.CONSTRAINT_NAME = t.CONSTRAINT_NAME
		WHERE TABLE_SCHEMA = @SourceSchema AND TABLE_NAME = @SourceTable
		OPEN constraintcursor;
		FETCH NEXT FROM constraintcursor INTO @ConstraintName, @CheckClause;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC('ALTER TABLE [' + @DestinationSchema + '].[' + @DestinationTable + '] WITH CHECK ADD CONSTRAINT [' + @ConstraintName + '] CHECK ' + @CheckClause)
			EXEC('ALTER TABLE [' + @DestinationSchema + '].[' + @DestinationTable + '] CHECK CONSTRAINT [' + @ConstraintName + ']')
			FETCH NEXT FROM constraintcursor INTO @ConstraintName, @CheckClause;
		END;
		CLOSE constraintcursor;
		DEALLOCATE constraintcursor;
	END TRY
	--Error Handling
	BEGIN CATCH
		PRINT 'Clone table failed due to errors'
		SELECT 
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_STATE() AS ErrorState
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH;
 
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
END


GO

GRANT VIEW DEFINITION ON [dbo].[DBA_CloneTableStructure] TO [vnteam] AS [dbo]
GO


