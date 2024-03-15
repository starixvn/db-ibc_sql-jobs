/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="wsv_lap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_Import]
	@DataSource		VARCHAR(200)
	,@CalledTime	DATETIME
	,@KeyValue		VARCHAR(200) = ''
	,@IsReset		BIT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Import data into API_TimeTracker
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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

		-- Remove old data: keep 1000 latest records
		DELETE t
		FROM (
			SELECT Id, ROW_NUMBER() OVER(ORDER BY Id DESC) AS RN
			FROM dbo.API_TimeTracker WITH (ROWLOCK, UPDLOCK)
			WHERE DataSource = @DataSource
		) t
		WHERE RN > 1000
	END
END
GO