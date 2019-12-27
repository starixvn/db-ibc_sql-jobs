/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_ReIndex]
AS
/*
	Created:
	Task: REORGANIZE
	DB: DBAGE.bodb02

	Revisions:
	-- Joe : reorganize all index with fragment > 30%
	-- 20140428@Lukas: join sys.schemas to avoid hardcode [dbo] schemas
	-- 20170220@Patrick: retry it when deadlock case
	-- 20191224@Patrick: Exclude bet14 on Friday schedule to avoid blocking between re-index and auto update statistics ( trigger by Friday routine task) [Redmine: #125989]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @__IsFriday BIT = 0
	IF DATENAME(W, GETDATE()) = 'Friday'
		SET @__IsFriday = 1

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
		AND 1 = CASE WHEN @__IsFriday = 1 AND tbl.name IN ('bettrans14', 'bettransRnG14', 'bettransLC14', 'bettransG14', 'translog14') THEN 0 ELSE 1 END
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