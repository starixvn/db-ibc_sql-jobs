/*<info serverAlias="DBTP-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRuntime_InitBU]
	@BUDate smalldatetime
	,@environment varchar(10)
	,@packageName varchar(100)
	,@creator varchar(100)
	,@sessionID varchar(50)
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

	DECLARE @runtimeID INT;
    
	-- Insert statements for procedure here
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[Environment]
           ,[StartTime]
           ,[Status]
		   ,[Creator])
     SELECT p.[PackageID]
           ,@environment AS [Environment]
           ,GETDATE() AS [StartTime]
           ,'Running' AS [Status]
		   ,@creator AS [Creator]
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;

	SET @runtimeID = SCOPE_IDENTITY();

	if @runtimeID > 0
	begin
		update rt with(rowlock,updlock)
		set ParentID = @sessionID, SessionID = @sessionID
		FROM [dbo].[SSIS_PackageRuntime] rt
		where rt.RuntimeID = @runtimeID;

		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
           ([RuntimeID]
           ,[ParamName]
           ,[ParamValue])
		SELECT @runtimeID AS [RuntimeID]
           ,'BUDate' AS [ParamName]
           ,CONVERT(char(10), @BUDate,126) AS [ParamValue]
	end

	SELECT @runtimeID AS RuntimeID, p.PackageID
	FROM dbo.SSIS_Package p with(nolock)
	where PackageName=@packageName;
END
GO
