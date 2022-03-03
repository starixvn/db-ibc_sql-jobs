/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Package_MappingTable_Select]
	@environment varchar(10)
	,@packageID int
	,@grantMode varchar(15)='Normal'
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20130831@Bobby: Init
		
	Explaination:
		- @runMode: Normal|Bet14
*/
BEGIN
	SET NOCOUNT ON;

	SELECT dt.ID AS SourceID
	FROM [dbo].[SSIS_DynamicMapping] dt WITH (NOLOCK)
		INNER JOIN [dbo].[SSIS_DynamicMapping_Package] pt WITH (NOLOCK) ON pt.[DynamicMappingID] = dt.[ID]
		INNER JOIN [dbo].[SSIS_Package] ps WITH (NOLOCK) ON ps.[PackageID] = pt.[PackageID]
		INNER JOIN [dbo].[SSIS_Package_ENV] pe WITH (NOLOCK) ON ps.[PackageID] = pe.[PackageID]
	WHERE ps.PackageID = @packageID
		AND dt.Active = 1
		AND pe.[Environment] = @environment
		AND pt.GrantMode = @grantMode

END
GO
