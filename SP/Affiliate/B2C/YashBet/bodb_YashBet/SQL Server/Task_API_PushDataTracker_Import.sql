/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_PushDataTracker_Import]
	@PushDataType	SMALLINT
	,@PushDataInfo	NVARCHAR(MAX) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(2000) = '' OUTPUT
	,@PushTrackerId BIGINT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Import data from API into API_PushDataTracker

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN

	SET NOCOUNT ON

	DECLARE @PushDataTracker TABLE (PushTrackerId BIGINT)

	SELECT  @ErrCode = 0, @ErrMsg = '', @PushTrackerId = 0

	BEGIN TRY

		INSERT INTO dbo.API_PushDataTracker(CheckInTime, StatusId, PushDataType, PushDataInfo)
		OUTPUT Inserted.PushTrackerId 
		INTO @PushDataTracker
		VALUES (GETDATE(), 0, @PushDataType, @PushDataInfo)
		
		SELECT @PushTrackerId = p.PushTrackerId
		FROM @PushDataTracker p

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
	END CATCH

	-- Remove old data
	DELETE dbo.API_PushDataTracker WITH (ROWLOCK, UPDLOCK)
	WHERE PushDataType = @PushDataType
		AND StatusId = 1 -- success
		AND FinishedTime < DATEADD(DAY, -7, GETDATE())

END
GO