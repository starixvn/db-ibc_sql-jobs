/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_PackageRuntime_Init]
	@environment varchar(10)
	,@creator varchar(100)
	,@sessionID INT
	,@packageName varchar(100)
	,@grantMode varchar(15)
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

	DECLARE @runtimeID INT;
    
	-- Insert statements for procedure here
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[Environment]
           ,[StartTime]
           ,[Status]
		   ,[Creator]
		   ,[SessionID])
     SELECT p.[PackageID]
           ,@environment AS [Environment]
           ,GETDATE() AS [StartTime]
           ,'Running' AS [Status]
		   ,@creator AS [Creator]
		   ,@sessionID AS [SessionID]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;

	SET @runtimeID = SCOPE_IDENTITY();

	if @runtimeID > 0
	begin
		update rt with(rowlock,updlock)
		set ParentID = @sessionID, SessionID=@sessionID
		FROM [dbo].[SSIS_PackageRuntime] rt
		where rt.RuntimeID = @runtimeID;

		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
           ([RuntimeID]
           ,[ParamName]
           ,[ParamValue])
		VALUES (@runtimeID, 'GrantMode', @grantMode)
			,(@runtimeID, 'PackageName', @packageName)
	end

	SELECT @runtimeID AS RuntimeID, p.PackageID
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;
END
GO