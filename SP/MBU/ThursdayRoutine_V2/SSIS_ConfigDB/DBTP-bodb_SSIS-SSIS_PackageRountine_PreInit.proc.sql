/*<info serverAlias="DBTP-bodb_SSIS" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRountine_PreInit]
	@packageID int
	, @environment VARCHAR(10)
	, @runtimeID INT
	, @sourceID INT
	, @outputFileDir VARCHAR(1000)
	, @sessionID varchar(50)
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP.bodb_SSIS
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @routineID INT;

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

	SELECT @routineID AS RoutineID, 0 AS Error
		,dt.SourceServer, dt.SourceDB
		,t.ExecCommand
		,ISNULL(@outputFileDir,'')+'\\'+@environment+'_'+CAST(@routineID AS varchar(10))+'_'+dt.TableName+ '_' + ti.subfix AS [outputFileName]
		,dt.OutputFileInfo
		,dt.BatchSize
		,dt.ChunkSize
		,dt.TableName
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
		select replace(replace(CONVERT(varchar(30), getdate(),126), ':','-'),'.','-')
	) as ti(subfix)
	WHERE dt.ID=@sourceID AND rp.ParamName = rt.ParamName;
END
GO
