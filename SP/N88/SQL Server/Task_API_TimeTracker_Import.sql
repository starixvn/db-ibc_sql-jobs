/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_Import]
	@DataSource		VARCHAR(200)
	,@CalledTime	DATETIME
	,@KeyValue		VARCHAR(50) = ''
	,@IsReset		BIT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Import data into API_TimeTracker

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]
		- 20200716@Percy: Add KeyValue [RedmineID: #137395]
		- 20200916@Percy: Add IsReset to reset setting value [RedmineID: #137395]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	IF @IsReset = 1
	BEGIN
		BEGIN TRY
			DELETE dbo.API_TimeTracker WITH (ROWLOCK, UPDLOCK)
			WHERE DataSource = @DataSource

			INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
			VALUES (@DataSource, @CalledTime, @KeyValue)
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		END CATCH
	END
	ELSE
	BEGIN
		BEGIN TRY
			INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
			VALUES (@DataSource, @CalledTime, @KeyValue)
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		END CATCH

		-- Remove old data
		DELETE dbo.API_TimeTracker WITH (ROWLOCK, UPDLOCK)
		WHERE DataSource = @DataSource
			AND CalledTime < DATEADD(MONTH, -1, GETDATE())
	END
END
GO