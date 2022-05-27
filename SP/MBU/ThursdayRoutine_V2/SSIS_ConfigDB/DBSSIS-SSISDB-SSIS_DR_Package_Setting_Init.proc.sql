/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_Package_Setting_Init]
	@environment varchar(10)='AWS'
	,@packageName varchar(100)=''
	,@creator varchar(100)=''
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

	DECLARE @HasENV bit
		,@SessionID INT
		,@processID int;

	with cte as (
		select 0 as IsENV
		union all
		SELECT top 1 1 as IsENV
		FROM dbo.SSIS_Package p with(nolock)
		inner join dbo.SSIS_Package_ENV e with(nolock) on e.PackageID = p.PackageID
		where e.Environment=@environment 
			and p.PackageName = @packageName
	)
	select @HasENV = CAST(MAX(t.IsENV) AS BIT) --AS HasENV
	FROM cte t
		
	INSERT INTO [dbo].[SSIS_PackageRuntime]
           ([PackageID]
           ,[DynamicMappingID]
           ,[Environment]
           ,[Command]
           ,[TargetInfo]
           ,[StartTime]
           ,[EndTime]
           ,[Status]
           ,[Creator]
           ,[ParentID]
           ,[SessionID])
	SELECT p.[PackageID]
		,NULL AS [DynamicMappingID]
        ,@environment AS [Environment]
        ,NULL AS [Command]
        ,NULL AS [TargetInfo]
        ,getdate() AS [StartTime]
        ,NULL AS [EndTime]
        ,'InProgress' AS [Status]
        ,@creator AS [Creator]
        ,0 AS [ParentID]
        ,@SessionID AS [SessionID]
	FROM dbo.SSIS_Package p with(nolock)
	WHERE p.PackageName=@packageName
	
	SET @processID = SCOPE_IDENTITY();

	IF @processID > 0
	BEGIN
		INSERT INTO [dbo].[SSIS_PackageRuntime_Param]
			   ([RuntimeID]
			   ,[ParamName]
			   ,[ParamValue])
		SELECT [RuntimeID]
			   ,[ParamName]
			   ,[ParamValue]
		FROM (
			VALUES 
			(@processID, 'HasENV', CAST(@HasENV AS char(10)))

		) AS t([RuntimeID],[ParamName],[ParamValue]);
		
		IF (@@SERVERNAME LIKE 'DBDW%')
		BEGIN	
			BEGIN TRY
				DECLARE @Notify  NVARCHAR(1000);
				SELECT @Notify = N'[' + @environment + '-' + @@SERVERNAME + ']@[DBA : SSIS Thursday-routine] started.'
				EXEC DBNOTI.NotificationDB.[dbo].[DBA_Skype_NewMessage]
							@ServerName			= 'PONTUS'
						,	@JobName			= N'Custom Message'
						,	@Message			= @Notify
			END TRY
			BEGIN CATCH
				--TODO:
			END CATCH
		END
	END

	SELECT @HasENV AS HasENV
		,@processID AS ProcessID
END
GO