/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_Process]
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Import data from API_Queue

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]
		- 20200716@Percy: Add 2 tables: TpTransferInfo & DepositInfo [RedmineID: #137395]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(2000)

	DECLARE @ErrTable TABLE (DataSource VARCHAR(200), ErrCode INT, ErrMsg NVARCHAR(2000))

	-- ServerInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_ServerInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('ServerInfo', @ErrCode, @ErrMsg)
		END
	END

	-- TpGameType
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpGameType @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpGameType', @ErrCode, @ErrMsg)
		END
	END

	-- Customer
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_Customer @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('Customer', @ErrCode, @ErrMsg)
		END
	END

	-- TpBetRecord
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpBetRecord @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpBetRecord', @ErrCode, @ErrMsg)
		END
	END

	-- TpTransferInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpTransferInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpTransferInfo', @ErrCode, @ErrMsg)
		END
	END

	-- DepositInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_DepositInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('DepositInfo', @ErrCode, @ErrMsg)
		END
	END

	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX), @recipients VARCHAR(MAX)

	-- In case having error
	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053')
			SELECT @recipients = 'percy.nguyen@starixsoft.com;sophia.nguyen@starixsoft.com;pontus@starixsoft.com'
		ELSE
			SELECT @recipients = 'percy.nguyen@starixsoft.com'

		SELECT @Subject = 'SQL Server Job System: ''Import data from API_Queue'' failed on ' + @@SERVERNAME

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