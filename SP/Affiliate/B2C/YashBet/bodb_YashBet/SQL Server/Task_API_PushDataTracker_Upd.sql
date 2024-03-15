/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="wsv_lap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_PushDataTracker_Upd]
	@PushTrackerId BIGINT
	,@StatusId	TINYINT = 2
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT

AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task:  Update Status Pushing Data from MPA to B2C 

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @StatusId
			. 0: InProcess
			. 1: Success
			. 2: Fail
*/

BEGIN

	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	BEGIN TRY		
		UPDATE a SET a.StatusId = @StatusId
			,a.FinishedTime = CASE WHEN @StatusId = 1 THEN GETDATE() ELSE a.FinishedTime END
		FROM dbo.API_PushDataTracker a WITH (ROWLOCK)
		WHERE a.PushTrackerId = @PushTrackerId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

END
GO