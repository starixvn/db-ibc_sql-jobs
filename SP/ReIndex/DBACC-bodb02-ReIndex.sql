/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_ReIndex]
AS
/*
Created:
	Task: REORGANIZE
	DB: DBAGE.bodb02

	Revisions:
	-- Joe : reorganize all index with fragment > 30%
	-- 20140428@Lukas: join sys.schemas to avoid hardcode [dbo] schemas
	-- Steven : Test VERSION if Reorganize index deadlock then try again after 2 min
	-- 20150417 @JoyChen :insert deadlock log to MonDB
	-- 20150420 @JoyChen :Index Reorganize Fail insert log to send mail
	-- 20150511 @JoyChen :Add DBName info in Message
	-- 20150601 @JoyChen :if happen deadlock more than two times or other Unexpected error to  job fail
	-- 20150609 @JoyChen :Add filter @@SERVERNAME ='DBBingoADMIN' and DB_NAME()='LiveCasinoAdmin' and tbl.name='GameLog'  not REORGANIZE
	-- 20150622 @JoyChen :Add Error Log when happen other Unexpected error and deadlock Twice
	-- 20160602 @JoyChen :waitfor 1 min when REORGANIZE about ticket table
	-- 20160608 @JoyChen :not do re-index UserLog_T  
	-- 20191224@Patrick: Exclude bet14 on Friday schedule to avoid blocking between re-index and auto update statistics ( trigger by Friday routine task) [Redmine: #125989]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__IsFriday BIT = 0
	IF DATENAME(W, GETDATE()) = 'Friday'
		SET @__IsFriday = 1

	declare @database_id int
	select @database_id = db_id()

	CREATE TABLE #CMDs (rn int PRIMARY KEY IDENTITY(1,1), cmd nvarchar(1000),rebuild_fg int,retry_fg int,TblName varchar(200),indexType varchar(1))			

	INSERT INTO #CMDs (cmd,rebuild_fg,retry_fg,TblName,indexType)
	SELECT
	--'ALTER INDEX [' + i.name + '] ON [dbo].[' + tbl.name + '] REORGANIZE',0,0
	'ALTER INDEX [' + i.name + '] ON [' + sch.name + '].[' + tbl.name + '] REORGANIZE',0,0,tbl.name,left(i.type_desc,1) as indexType 
	--fi.avg_fragmentation_in_percent AS [AverageFragmentation]
	FROM
	sys.tables AS tbl
	INNER JOIN sys.schemas sch ON tbl.schema_id = sch.schema_id
	INNER JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
	INNER JOIN sys.dm_db_index_physical_stats(@database_id, NULL, NULL, NULL, 'LIMITED') AS fi ON fi.object_id=CAST(i.object_id AS int) AND fi.index_id=CAST(i.index_id AS int)
	WHERE
		fi.avg_fragmentation_in_percent > 30
		AND tbl.name NOT LIKE 'BalanceRecord%'
		AND tbl.name not in ('UserLog_T')
		AND sch.name NOT LIKE 'DataSync%'
		AND 1 = CASE WHEN @__IsFriday = 1 AND tbl.name IN ('bettrans14', 'bettransRnG14', 'bettransLC14', 'bettransG14', 'translog14') THEN 0 ELSE 1 END
	ORDER BY tbl.name, i.type_desc

	declare @rn int, @cmd nvarchar(1000)  ,@TblName varchar(200),@indexType varchar(1)


	WHILE EXISTS(SELECT 1 FROM #CMDs WHERE rebuild_fg=0 or (rebuild_fg=1 and  retry_fg=1))
	BEGIN
		BEGIN TRY
	    
			SELECT top 1 @rn=rn ,@TblName=TblName,@indexType=indexType FROM #CMDs WHERE rebuild_fg=0 or (rebuild_fg=1 and  retry_fg=1)	
			SELECT @cmd = cmd FROM #CMDs WHERE rn = @rn	
			EXEC sp_executesql @cmd
		
		
		END TRY

		BEGIN CATCH
		
			DECLARE @ErrorMessage VARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
	
			SELECT  @ErrorMessage = ERROR_MESSAGE(),
					@ErrorSeverity =ERROR_SEVERITY(),
					@ErrorState = ERROR_STATE();

			IF @ErrorMessage like'%deadlock%' 
				BEGIN 
			
					UPDATE #CMDs SET retry_fg=ISNULL(retry_fg,0)+1 WHERE rn = @rn	

					INSERT INTO MONDB.dbo.Mon_EventLogs
					( EventDT, ComputerName, SourceName, Type, Message, Cnt, IsAlert)
					SELECT GETDATE() as [EventTime]
						  ,@@SERVERNAME
						  ,DB_NAME() as [SourceName]
						  ,'ReIndex_deadlock' as [Type]
						  --,'@TableName : '+SUBSTRING(cmd,charindex('[dbo].[',cmd)+7,charindex('] REORGANIZE',cmd)-(charindex('[dbo].[',cmd)+7)) +' @IndexName : '+ SUBSTRING(cmd,14,charindex('] ON [dbo].[',cmd)-14)
						  ,'@TableName : '+SUBSTRING(cmd,charindex('].[',cmd)+3,charindex('] REORGANIZE',cmd)-(charindex('].[',cmd)+3)) +' @IndexName : '+ SUBSTRING(cmd,14,charindex('] ON [',cmd)-14)
						  ,0 as Cnt
						  ,'Y' as IsAlert---no send mail
					FROM #CMDs 
					WHERE rn = @rn	

					IF 1=isnull((SELECT 1 FROM #CMDs WHERE rn = @rn  and rebuild_fg=0 and  retry_fg=1),0)
						Begin		
							waitfor delay '00:02'
						end
					ELSE IF 1=isnull((SELECT 1 FROM #CMDs WHERE rn = @rn  and rebuild_fg=1 and  retry_fg=2),0)
						Begin
							INSERT INTO MONDB.dbo.Mon_EventLogs
							( EventDT, ComputerName, SourceName, Type, Message, Cnt, IsAlert)
							SELECT GETDATE() as [EventTime]
								  ,@@SERVERNAME
								  ,DB_NAME() as [SourceName]
								  ,'ReIndex_deadlock Twice' as [Type]
								  --,'@TableName : '+SUBSTRING(cmd,charindex('[dbo].[',cmd)+7,charindex('] REORGANIZE',cmd)-(charindex('[dbo].[',cmd)+7)) +' @IndexName : '+ SUBSTRING(cmd,14,charindex('] ON [dbo].[',cmd)-14)
								  ,'@TableName : '+SUBSTRING(cmd,charindex('].[',cmd)+3,charindex('] REORGANIZE',cmd)-(charindex('].[',cmd)+3)) +' @IndexName : '+ SUBSTRING(cmd,14,charindex('] ON [',cmd)-14)
								  ,0 as Cnt
								  ,'Y' as IsAlert---no send mail
							FROM #CMDs 
							WHERE rn = @rn	
				        
							RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState)
							RETURN
						end
				END
			ELSE 
				BEGIN
				
					INSERT INTO MONDB.dbo.Mon_EventLogs
					( EventDT, ComputerName, SourceName, Type, Message, Cnt, IsAlert)
					SELECT GETDATE() as [EventTime]
						  ,@@SERVERNAME
						  ,DB_NAME() as [SourceName]
						  ,'ReIndex Error' as [Type]
						  --,'@TableName : '+SUBSTRING(cmd,charindex('[dbo].[',cmd)+7,charindex('] REORGANIZE',cmd)-(charindex('[dbo].[',cmd)+7)) +' @ErrorMessage : '+ @ErrorMessage
						  ,'@TableName : '+SUBSTRING(cmd,charindex('].[',cmd)+3,charindex('] REORGANIZE',cmd)-(charindex('].[',cmd)+3)) +' @ErrorMessage : '+ @ErrorMessage
						  ,0 as Cnt
						  ,'Y' as IsAlert---no send mail
					FROM #CMDs 
					WHERE rn = @rn	 
	    
					RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState)
					RETURN
				END	
					
		END  CATCH
	
		UPDATE #CMDs SET rebuild_fg=rebuild_fg+1 WHERE rn = @rn
	
		IF @indexType='C' and @TblName in ('UserLog_P','userlog','bettrans','bettrans14','translog','translog14','bettransm','bettransm14','bettransG','bettransG14','bettransRnG','bettransRnG14') 
		BEGIN
			waitfor delay '00:01'
		END
	 
	END

	EXEC sp_updatestats
	  --DBCC DROPCLEANBUFFERS	
END
GO
