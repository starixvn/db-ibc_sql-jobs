/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_PackageRountine_EndUpdate]
	@rountineID int
	, @error int
	, @message varchar(250)
	, @rowCount int
	, @FileID INT
	, @IsCanceled BIT = 0
	, @DR_FileID INT
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

	UPDATE rt WITH(ROWLOCK, UPDLOCK)
	SET Status = case 
			when @IsCanceled = 1 then 'Canceled' 
			when @error > 0 then 'Failed' 
			else 'Completed'  end
		,EndTime=getdate()
		,Error=@error, Message=case when @error>0 then @message end
		,RowTotal=@rowCount
	FROM dbo.SSIS_PackageRuntime rt
	WHERE RuntimeID=@rountineID

	IF @@ERROR = 0
	BEGIN
		UPDATE uf WITH(ROWLOCK,UPDLOCK)
		SET DR_Status = case 
				when @IsCanceled = 0 AND @error = 0 then 1
				else 0  end
			,DR_UpdatedTime = GETDATE()
		FROM dbo.SSIS_DynamicMapping_OutputFile AS uf
		WHERE FileID = @FileID

		UPDATE df WITH(ROWLOCK,UPDLOCK)
		SET [Status] = case 
				when @IsCanceled = 1 then 'Canceled' 
				when @error > 0 then 'Failed' 
				else 'Completed'  end
			, DR_Sync = case 
				when @IsCanceled = 0 AND @error = 0 then 1
				else 0  end
			, RowTotal = @rowCount
		FROM dbo.SSIS_DR_DynamicMapping_ProcessFile AS df
		WHERE FileID = @DR_FileID
	END

	-- RETURN
	Select @error AS Error
END
GO