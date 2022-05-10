/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_DynamicMapping_ListFile]
	@PackageID INT = 5
	,@GrantMode VARCHAR(50) = 'Bet14'
	,@Environment VARCHAR(10) = 'AWS'
AS
/*
	Created by:	20220415@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20220415@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	SELECT FileID, d.ID AS SourceID, DataFile, SchemaFile
	FROM [dbo].[SSIS_DynamicMapping_OutputFile] df WITH(NOLOCK)
	INNER JOIN dbo.SSIS_DynamicMapping d WITH(NOLOCK) ON d.ID = df.DynamicMappingID
	INNER JOIN dbo.SSIS_DynamicMapping_Package pd WITH(NOLOCK) ON pd.DynamicMappingID = d.ID
	INNER JOIN dbo.SSIS_Package_ENV evn WITH(NOLOCK) ON evn.PackageID = pd.PackageID
	CROSS APPLY (
		SELECT df.[FileName]
			, REPLACE(df.[FileName],'.csv','.xml')
	) c(DataFile, SchemaFile)
	WHERE pd.PackageID =  @PackageID
		AND pd.GrantMode = @GrantMode
		AND df.[DR_Status] = 0
		AND evn.Environment=@Environment
		AND d.Active = 1

END
GO