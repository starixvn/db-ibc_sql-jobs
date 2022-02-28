/*<info serverAlias="DBWH-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRuntime_EndUpdate]
	@runtimeID int
	,@runtimeError bit
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

	update rt with(rowlock,updlock)
	set 
		[Status] = case when @runtimeError = 1 then 'Failed' else 'Completed' end
		,Error = @runtimeError
		,EndTime = getdate()
	from dbo.SSIS_PackageRuntime rt
	where rt.RuntimeID = @runtimeID;
END
GO
