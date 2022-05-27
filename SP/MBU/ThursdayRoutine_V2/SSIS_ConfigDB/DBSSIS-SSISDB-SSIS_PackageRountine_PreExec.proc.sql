/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRountine_PreExec]
	@sourceID INT
	, @environment VARCHAR(10)
	, @runningDate DATE = NULL
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20130831@Bobby: Init
		- 20220518@Bobby: Support partitioned view [Redmine: #166146]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @targetInfo VARCHAR(8000), @partitionedView INT;

	SELECT @partitionedView = CASE WHEN @runningDate IS NOT NULL THEN YEAR(@runningDate) ELSE YEAR(CURRENT_TIMESTAMP) END

	SELECT @targetInfo = COALESCE(@targetInfo + ';', '') + (tr.[TargetServer]+'#'+tr.[TargetDB]+'#' + CASE WHEN tr.[IsPartitionedView]=1 THEN REPLACE(tr.[TargetTable], 'VIEW', CAST(@partitionedView AS VARCHAR(10))) ELSE tr.[TargetTable] END) 
	FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
	inner join [dbo].[SSIS_DynamicMapping_Target] tr with(nolock) on tr.[DynamicMappingID] = dt.[ID] 
	WHERE dt.ID=@sourceID AND tr.Active=1 and tr.Environment=@environment;

	-- output
	select @targetInfo as [TargetInfo]
		,dt.IsCanceled
	FROM dbo.SSIS_DynamicMapping dt WITH(NOLOCK)
	WHERE dt.ID=@sourceID;
END
GO
