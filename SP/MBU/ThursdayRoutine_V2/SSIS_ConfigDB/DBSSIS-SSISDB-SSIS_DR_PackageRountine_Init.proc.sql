/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_PackageRountine_Init]
	@PackageID int
	, @Environment VARCHAR(10)
	, @RuntimeID INT
	, @GrantMode VARCHAR(1000)
	, @SessionID INT
	, @DataFile varchar(1000)
	, @SourceID  INT
	, @RunningDate DATE = NULL
AS
/*
	Created by:	20220415@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20220415@Bobby: Init
		- 20220518@Bobby: Support partitioned view [Redmine: #166146]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @routineID INT
		,@error INT = 0
		,@sourceServer VARCHAR(100)
		,@sourceDB VARCHAR(100)
		,@execCommand VARCHAR(1000)
		,@sourceTable VARCHAR(100)
		,@DR_FileID INT

		,@batchSize INT
		,@chunkSize INT
		,@syncParallel BIT
		,@rowTotal INT = 0
		,@targetInfo VARCHAR(1000)
		,@isCanceled BIT
		,@partitionedView INT;

	SELECT @partitionedView = CASE WHEN @runningDate IS NOT NULL THEN YEAR(@runningDate) ELSE YEAR(CURRENT_TIMESTAMP) END;

	INSERT INTO [dbo].[SSIS_PackageRuntime]
		([PackageID],[DynamicMappingID]
		,[Environment]
		,[StartTime]
		,[Status]
		,[ParentID]
		,[SessionID])
	SELECT p.[PackageID], d.ID AS [DynamicMappingID]
		,@environment  AS [Environment]
		,GETDATE() AS [StartTime]
		,'Running' AS [Status]
		,@runtimeID AS [ParentID]
		,@sessionID AS [SessionID]
	
	FROM dbo.SSIS_Package p with(nolock)
	INNER JOIN dbo.SSIS_DynamicMapping_Package dp WITH(NOLOCK) ON dp.PackageID = p.PackageID
	INNER JOIN dbo.SSIS_Package_ENV env WITH(NOLOCK) ON env.PackageID = p.PackageID
	INNER JOIN dbo.SSIS_DynamicMapping d WITH(NOLOCK) ON d.ID = dp.DynamicMappingID 
	where p.PackageID=@packageID
		AND env.Environment = @Environment
		AND d.ID = @SourceID
		AND dp.GrantMode = @GrantMode;

	SET @routineID = SCOPE_IDENTITY();

	IF @routineID > 0
	BEGIN
		SELECT @error = 0
			,@sourceID = dt.ID
			,@sourceServer = dt.SourceServer
			,@sourceDB = dt.SourceDB
			,@execCommand = @DataFile
			,@BatchSize = dt.BatchSize
			,@chunkSize = dt.ChunkSize
			,@syncParallel = ISNULL(dt.SyncParallel,0)
			,@isCanceled = ISNULL(IsCanceled, 0)
			,@sourceTable = dt.TableName
		FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
		WHERE dt.ID=@SourceID;

		-- match target
		SELECT @targetInfo = COALESCE(@targetInfo + ';', '') + (tr.[TargetServer]+'#'+tr.[TargetDB]+'#'+ CASE WHEN tr.[IsPartitionedView]=1 THEN REPLACE(tr.[TargetTable], 'VIEW', CAST(@partitionedView AS VARCHAR(10))) ELSE tr.[TargetTable] END) 
		FROM [dbo].[SSIS_DynamicMapping_Target] tr with(nolock) 
		WHERE tr.DynamicMappingID=@SourceID AND tr.Active=1 and tr.Environment=@environment;

		-- update back target vs exec command
		UPDATE rt with(rowlock, updlock)
		SET Command = @execCommand
			, TargetInfo = @targetInfo
		FROM [dbo].[SSIS_PackageRuntime] rt
		WHERE RuntimeID = @routineID;

		INSERT INTO [dbo].[SSIS_DR_DynamicMapping_ProcessFile]
           ([RuntimeID],[DynamicMappingID]
		   ,[FilePath]
           ,[Status]
		   ,[DR_Sync]
           ,[CreateTime])
		SELECT [RuntimeID] = @routineID
			, [DynamicMappingID] = @sourceID
			, [FilePath] = @DataFile
			, [Status] = 'Running'
			, [DR_Sync] = 0
			, [CreateTime] = GETDATE()

		SET @DR_FileID = SCOPE_IDENTITY();

	END

	SELECT @routineID AS RoutineID
		,@error AS Error
		,'' AS [Message]
		,@targetInfo AS TargetInfo
		,@batchSize AS [BatchSize]
		,@chunkSize AS ChunkSize
		,@sourceID AS SourceID
		,@syncParallel AS SyncParallel
		,@rowTotal AS RowTotal
		,@isCanceled AS  IsCanceled
		,@sourceTable AS SourceTable
		,@DR_FileID AS DR_FileID
END
GO