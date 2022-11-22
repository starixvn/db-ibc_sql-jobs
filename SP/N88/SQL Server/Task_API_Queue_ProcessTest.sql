/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_ProcessTest]
AS

/*
	Created: 20221011@Malcolm
	DB: DBN88-bodb_N88
	Task: Import data from API_QueueTest

	Revisions:
		- 20221011@Malcolm: Initialize SP [RedmineID: #177893]
		
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(2000)

	DECLARE @ErrTable TABLE (DataSource VARCHAR(200), ErrCode INT, ErrMsg NVARCHAR(2000))

	-- TpBetRecordTest
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpBetRecordTest @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpBetRecordTest', @ErrCode, @ErrMsg)
		END
	END

	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX), @recipients VARCHAR(MAX)

	-- In case having error
	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053')
			SELECT @recipients = 'sophia.nguyen@starixvn.com;pontus@starixvn.com'
		ELSE
			SELECT @recipients = 'sophia.nguyen@starixvn.com'

		SELECT @Subject = 'SQL Server Job System: ''Import data from API_QueueTest'' failed on ' + @@SERVERNAME

		SELECT @Msg = '<H3>List of tables have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Table</th><th>Error Message</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = DataSource, '',
										td = ErrMsg, ''
								FROM @ErrTable
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX) ) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= @recipients,
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO