/*<info serverAlias="DBTP-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRountine_PreInit]
	@packageID int
	, @environment VARCHAR(10)
	, @runtimeID INT
	, @sourceID INT
	, @outputFileDir VARCHAR(1000)
	, @sessionID varchar(50)
	, @targetInfo varchar(1000)=''
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP.SSISDB
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @routineID INT
		,@error INT = 0
		,@sourceServer VARCHAR(100)
		,@sourceDB VARCHAR(100)
		,@execCommand VARCHAR(1000)
		,@outputFileName  VARCHAR(1000)
		,@outputFileInfo  VARCHAR(100)
		,@batchSize INT
		,@chunkSize INT
		,@tableName  VARCHAR(100)
		,@syncParallel BIT
		,@rowTotal INT = 0;

	INSERT INTO [dbo].[SSIS_PackageRuntime]
		([PackageID],[DynamicMappingID]
		,[Environment]
		,[StartTime]
		,[Status]
		,[ParentID]
		,[SessionID])
	SELECT p.[PackageID], @sourceID AS [DynamicMappingID]
		,@environment  AS [Environment]
		,GETDATE() AS [StartTime]
		,'Running' AS [Status]
		,@runtimeID AS [ParentID]
		,@sessionID AS [SessionID]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageID=@packageID;

	SET @routineID = SCOPE_IDENTITY();

	IF @routineID > 0
	BEGIN
		SELECT @error = 0
			,@sourceServer = dt.SourceServer
			,@sourceDB = dt.SourceDB
			,@execCommand = t.ExecCommand
			,@outputFileName = ISNULL(@outputFileDir,'')+'\\'+@environment+'_'+CAST(@routineID AS varchar(10))+'_'+dt.TableName+ '_' + ti.subfix 
			,@outputFileInfo = dt.OutputFileInfo
			,@BatchSize = dt.BatchSize
			,@chunkSize = dt.ChunkSize
			,@tableName = dt.TableName
			,@syncParallel = ISNULL(dt.SyncParallel,0)
		FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
		CROSS APPLY (
			--select 'winlostdate' as 'ParamName', '2021-04-30' as ParamValue
			SELECT TOP 1 ParamName, ParamValue
			FROM dbo.SSIS_PackageRuntime_Param p with(nolock)
			WHERE p.RuntimeID = @runtimeID
		) AS rp
		CROSS APPLY (
			SELECT TOP 1 tp.ParamName
			FROM dbo.[SSIS_DynamicMapping_Param] tp with(nolock)
			WHERE tp.DynamicMappingID = dt.ID
		) AS rt
		cross apply (
			select 
				case 
					when dt.CommandType = 'SP' THEN 'EXEC ' + dt.[ExecCommand] + ' @'+rt.ParamName +'=''' + rp.ParamValue + '''' 
				else REPLACE(dt.[ExecCommand], '@'+rt.ParamName, '''' + rp.ParamValue +'''')
			END AS [ExecCommand]
		) as t
		cross apply (
			SELECT REPLACE(REPLACE(CONVERT(varchar(30), getdate(),126), ':','-'),'.','-')
		) as ti(subfix)
		WHERE dt.ID=@sourceID AND rp.ParamName = rt.ParamName;

		-- update back target vs exec command
		UPDATE rt
		SET Command = @execCommand
			, TargetInfo = @targetInfo
		FROM [dbo].[SSIS_PackageRuntime] rt
		WHERE RuntimeID = @routineID;

	END

	SELECT @routineID  AS RoutineID
		,@error AS Error
		,@sourceServer AS SourceServer
		,@sourceDB AS SourceDB
		,@execCommand AS ExecCommand
		,@outputFileName AS OutputFileName
		,@outputFileInfo AS OutputFileInfo
		,@batchSize AS [BatchSize]
		,@chunkSize AS ChunkSize
		,@tableName AS TableName
		,@syncParallel AS SyncParallel
		,@rowTotal AS RowTotal
END
GO
