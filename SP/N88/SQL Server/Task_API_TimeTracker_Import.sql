/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_Import]
	@DataSource		VARCHAR(200)
	,@CalledTime	DATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Get latest called API time

	Revisions:
		- 20200520@Percy: Initalize SP [RedmineID: #133254]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	BEGIN TRY
		INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime)
		VALUES (@DataSource, @CalledTime)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
	END CATCH

	-- Remove old data
	DELETE dbo.API_TimeTracker WITH (ROWLOCK, UPDLOCK)
	WHERE DataSource = @DataSource
		AND CalledTime < DATEADD(MONTH, -1, GETDATE())
END
GO