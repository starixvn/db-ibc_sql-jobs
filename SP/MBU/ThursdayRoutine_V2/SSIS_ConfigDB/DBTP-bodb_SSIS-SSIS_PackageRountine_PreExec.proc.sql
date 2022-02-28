/*<info serverAlias="DBWH-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRountine_PreExec]
	@sourceID INT
	, @environment VARCHAR(10)
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

	DECLARE @targetInfo VARCHAR(8000);

	SELECT @targetInfo = COALESCE(@targetInfo + ';', '') + (tr.[TargetServer]+'#'+tr.[TargetDB]+'#'+tr.[TargetTable]) 
	FROM [dbo].[SSIS_DynamicMapping] dt with(nolock)
	inner join [dbo].[SSIS_DynamicMapping_Target] tr with(nolock) on tr.[DynamicMappingID] = dt.[ID] 
	WHERE dt.ID=@sourceID AND tr.Active=1 and tr.Environment=@environment;

	select @targetInfo as [TargetInfo];
END
GO
