/*<info serverAlias="DBPTCS-bodb_PlaytechCS" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_ReIndex]
AS
/*
	Created:
	Task: REORGANIZE

	Revisions:
	-- Joe : reorganize all index with fragment > 30%
	-- 20140428@Lukas: join sys.schemas to avoid hardcode [dbo] schemas
	-- 20170220@Patrick: retry it when deadlock case
	-- 20191224@Patrick: Skip re-index for logshiping databases [Redmine: #125989]
*/
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (
		SELECT TOP 1 1
		FROM master.sys.databases d WITH(NOLOCK)
		WHERE d.state = 0 AND d.is_in_standby = 0
			AND database_id = db_id()
	)
	BEGIN
		PRINT 'skip re-index for logshiping databases'
		RETURN
	END

	DECLARE @CMDs TABLE (rn INT PRIMARY KEY IDENTITY(1,1), cmd NVARCHAR(1000))			

	INSERT INTO @CMDs (cmd)
	SELECT 'ALTER INDEX [' + i.name + '] ON [' + sch.name + '].[' + tbl.name + '] REORGANIZE'
	FROM sys.tables AS tbl
		INNER JOIN sys.schemas sch ON tbl.schema_id = sch.schema_id
		INNER JOIN sys.indexes AS i ON i.index_id > 0 AND i.is_hypothetical = 0 AND i.object_id = tbl.object_id
		INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS fi ON fi.object_id = i.object_id AND fi.index_id = i.index_id
	WHERE fi.avg_fragmentation_in_percent > 30
		AND tbl.name NOT LIKE 'BalanceRecord%'
		AND sch.name NOT LIKE 'DataSync%'
	ORDER BY tbl.name, i.type_desc

	DECLARE @rn INT, @cmd NVARCHAR(1000)
	SET @rn = 1
	
	--select * from @CMDs
	WHILE EXISTS(SELECT 1 FROM @CMDs WHERE rn = @rn)
	BEGIN
		SELECT @cmd = cmd FROM @CMDs WHERE rn = @rn
		SET @rn = @rn + 1

		BEGIN TRY
			EXEC sp_executesql @cmd
		END TRY
		BEGIN CATCH
			DECLARE @errorNumber INT, @errorMessage VARCHAR(200), @errorSeverity INT, @errorState INT

			SELECT @errorNumber = ERROR_NUMBER()
				, @errorMessage = ERROR_MESSAGE()
				, @errorSeverity = ERROR_SEVERITY()
				, @errorState = ERROR_STATE()

			IF @errorNumber = 1205 --deadlock
			BEGIN
				PRINT @errorMessage
				WAITFOR DELAY '00:01:00:000' --waitfor 1 min

				INSERT INTO MONDB.dbo.Mon_EventLogs(EventDT, ComputerName, SourceName, Type, Message, Cnt, IsAlert)
				SELECT GETDATE() AS EventTime
					, @@SERVERNAME AS ComputerName
					, DB_NAME() AS SourceName
					, 'Error' AS Type
					, 'Failed to rebuild: [' + @cmd + ']. Error message [' + @errorMessage + '].'
					, 1 AS Cnt
					, 'Y' AS IsAlert ---no send mail

				EXEC sp_executesql @cmd --retry

			END
			ELSE --others will raise error and terminate session
			BEGIN
				INSERT INTO MONDB.dbo.Mon_EventLogs(EventDT, ComputerName, SourceName, Type, Message, Cnt, IsAlert)
				SELECT GETDATE() AS EventTime
					, @@SERVERNAME AS ComputerName
					, DB_NAME() AS SourceName
					, 'Error' AS Type
					, 'Failed to rebuild: [' + @cmd + ']. Error message [' + @errorMessage + '].'
					, 0 AS Cnt
					, 'Y' AS IsAlert ---no send mail

				RAISERROR (@errorMessage, -- Message text.
					   @errorMessage, -- Severity.
					   @errorState -- State.
					   );
			END

		END CATCH
	END

	EXEC sp_updatestats
END
