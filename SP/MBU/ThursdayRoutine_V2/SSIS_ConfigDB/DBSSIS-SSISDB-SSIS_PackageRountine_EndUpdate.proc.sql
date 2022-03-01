/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRountine_EndUpdate]
	@rountineID int
	, @command varchar(1000)
	, @rowCount int
	, @error int
	, @message varchar(250)
	, @targetInfo varchar(1000)
	, @outputFileName varchar(1000)
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	UPDATE rt WITH(ROWLOCK, UPDLOCK)
	SET command=@command
		,Status = case when @error>0 then 'Failed' else 'Completed'  end
		,EndTime=getdate()
		,Error=@error, Message=case when @error>0 then @message end
		,RowTotal=@rowCount
		,TargetInfo=@targetInfo
	FROM dbo.SSIS_PackageRuntime rt
	WHERE RuntimeID=@rountineID

	IF ISNULL(@rowCount,0) > 0 AND LEN(@outputFileName) > 0 and isnull(@error,0) = 0
	BEGIN
		INSERT INTO [dbo].[SSIS_DynamicMapping_OutputFile]
			([RuntimeID]
			,[DynamicMappingID]
			,[FileName]
			,[RowTotal]
			,[ARC_Status]
			,[HA_Status]
			,[DR_Status]
			,[CreateTime])
		SELECT [RuntimeID]
			,[DynamicMappingID]
			,@outputFileName + '.csv' AS [FileName]
			,@rowCount AS [RowTotal]
			,1 AS [ARC_Status]
			,1 AS [HA_Status]
			,0 AS [DR_Status]
			,GETDATE() AS [CreateTime]
		FROM dbo.SSIS_PackageRuntime WITH(NOLOCK)
		WHERE RuntimeID=@rountineID
	END

	-- RETURN
	Select @error AS Error
END
GO
