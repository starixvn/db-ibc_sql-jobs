/*<info serverAlias="DBCUST-CustDB,DBACC-bodb02,DBAGE-bodb02,DBTXN-CustDB,DBBOF-bodb02,DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Repl_CleanDeletedData] 
AS
/*
		Created: 20231227@Eden	
		Task: Job clean data replication in-house tables with isDeleted = 1
		DB: DBCUST-CustDB,DBACC-bodb02,DBAGE-bodb02,DBTXN-CustDB,DBBOF-bodb02,DBTP-bodb02
		
		Revisions:
			- 20231227@Eden	: Initial Version #198589

		Parameters Explanation:	
*/
BEGIN
	DECLARE @DeleteDate_From DATETIME, 
		@DeleteDate_To DATETIME, 
		@DatabaseName VARCHAR(100), 
		@TableName VARCHAR(100), 
		@Version_Key VARCHAR(100), 
		@Unique_Key VARCHAR(100), 
		--Parameters: Dynamic query check valid object
		@msg_Err1 VARCHAR(500),
		@msg_Err2 VARCHAR(500),
		@ParmDefinition_Object NVARCHAR(500),
		@ExistObject BIT ,
		@HaveUpdateDB BIT,
		--Parameters: Dynamic query clean data
		@Batch_Num INT = 4000,
		@sql_str NVARCHAR(MAX) = '',
		@ParmDefinition NVARCHAR(500),
		@msg VARCHAR(500),
		@JoinCondition VARCHAR(500) = ''
	
	SET @DeleteDate_To = DATEADD(hh,-24, GETDATE())
	SET @ParmDefinition = N'@DeleteDate_To DATETIME, @DeleteDate_FROM DATETIME'
	SET @ParmDefinition_Object = N'@ExistObject BIT OUTPUT, @HaveUpdateDB BIT OUTPUT'
	SET @msg = 'DatabaseName: %s, TableName: %s, Version_Key: %s. '
	SET @msg_Err1 = 'This table does not exist on this database'
	SET @msg_Err2 = 'This database is not exist or Read-Only'

	DECLARE @Rep_Tables TABLE (DatabaseName VARCHAR(100),TableName VARCHAR(100), Version_Key VARCHAR(100),Unique_Key VARCHAR(100),CleanFromDate	DATETIME, Isfinish BIT DEFAULT 0)
	INSERT INTO @Rep_Tables(DatabaseName,TableName,Version_Key,Unique_Key,CleanFromDate)
	SELECT DatabaseName,TableName,Version_Key,REPLACE(Unique_Key, '|',','),ISNULL(CleanFromDate,'')
	FROM RepInfo_CleanData (NOLOCK) 

	DECLARE @Unique_Key_Tables TABLE(ColName VARCHAR(100))

	PRINT '----------------------------START CLEAN DATA-----------------------'

	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1) t
		SET @DatabaseName = DatabaseName,
			@TableName= TableName,
			@Version_Key = Version_Key,
			@Unique_Key = Unique_Key,
			@DeleteDate_From = CleanFromDate,
			Isfinish = 1
		FROM @Rep_Tables t
		WHERE t.Isfinish = 0

		IF @@ROWCOUNT = 0
			BREAK;

		RAISERROR (@msg,10,1,@DatabaseName,@TableName,@Version_Key)

		SET @sql_str = '
		IF DATABASEPROPERTYEX('''+ @DatabaseName + ''', ''Updateability'')  = ''READ_WRITE''
		BEGIN
			SET @HaveUpdateDB = 1

			IF OBJECT_ID('''+ @DatabaseName + '.[dbo].' + @TableName +''') IS NOT NULL
				SET @ExistObject = 1
			ELSE 
				SET @ExistObject = 0
		END
		ELSE
		BEGIN
			SET @HaveUpdateDB = 0
			SET @ExistObject = 0
		END
		'
		PRINT (@sql_str)
		EXECUTE sp_executesql 
			  @sql_str,
			  @ParmDefinition_Object,
			  @ExistObject = @ExistObject OUTPUT,
			  @HaveUpdateDB = @HaveUpdateDB OUTPUT

		IF @ExistObject = 1 AND @HaveUpdateDB = 1
		BEGIN
			SET @JoinCondition = ''
			DELETE FROM @Unique_Key_Tables

			INSERT INTO @Unique_Key_Tables(ColName)
			SELECT LTRIM(RTRIM(value)) 
			FROM STRING_SPLIT(@Unique_Key,',')

			SELECT @JoinCondition = @JoinCondition + CHAR(13) + CHAR(10) + 'AND c.' + tb.ColName + ' = t.' + tb.ColName 
			FROM @Unique_Key_Tables tb

			SET @JoinCondition = STUFF( @JoinCondition, 1, 6, '')

			--PRINT @JoinCondition
			
			SET @sql_str = '
			SELECT '+ @Unique_Key +'
			INTO #Temp
			FROM ' + @DatabaseName + '.[dbo].' + @TableName + ' t WITH(NOLOCK)
			WHERE IsDeleted = 1
				AND ' +  @Version_Key + ' >= @DeleteDate_From 
				AND ' +  @Version_Key + ' < @DeleteDate_To 
			UNION ALL --remove identity auto generate
			SELECT TOP(0) '+ @Unique_Key +'
			FROM ' + @DatabaseName + '.[dbo].' + @TableName + ' t WITH(NOLOCK)
			WHERE 1 = 0

			SELECT TOP(0) '+ @Unique_Key +'
			INTO #Temp_batch
			FROM #Temp
			WHERE 1 = 0

			WHILE 1 = 1
			BEGIN
				TRUNCATE TABLE #Temp_batch

				INSERT INTO #Temp_batch('+ @Unique_Key +')
				SELECT TOP ('+ CONVERT(VARCHAR(10),@Batch_Num) + ') ' + @Unique_Key +'
				FROM #Temp t

				IF @@ROWCOUNT = 0
					BREAK;

				DELETE c
				FROM ' + @DatabaseName + '.[dbo].' + @TableName + ' c WITH(ROWLOCK,UPDLOCK)
					INNER JOIN #Temp_batch t 
						ON '+ @JoinCondition +'
				WHERE c.IsDeleted = 1

				DELETE c
				FROM #Temp c
					INNER JOIN #Temp_batch t 
						ON '+ @JoinCondition +'

				WAITFOR DELAY ''00:00:00.500''
			END
				'

			PRINT '@DeleteDate_From : ' + CONVERT(VARCHAR(20), @DeleteDate_From,120)
			PRINT '@DeleteDate_To : ' + CONVERT(VARCHAR(20), @DeleteDate_To,120)
			PRINT @sql_str

			EXECUTE sp_executesql 
				@sql_str,
				@ParmDefinition,
				@DeleteDate_To = @DeleteDate_To,
				@DeleteDate_From = @DeleteDate_From

			UPDATE TOP(1) t
			SET t.CleanFromDate =  DATEADD(hh,-1, @DeleteDate_To)  
			FROM RepInfo_CleanData t WITH(ROWLOCK,UPDLOCK)
			WHERE t.DatabaseName = @DatabaseName
				AND t.TableName = @TableName
		END
		ELSE IF @HaveUpdateDB = 0
		BEGIN
			RAISERROR (@msg_Err2,10,1)
		END
		ELSE
		BEGIN
			RAISERROR (@msg_Err1,10,1)
		END
	END
	PRINT '----------------------------END CLEAN DATA-----------------------'
END
GO
