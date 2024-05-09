/*<info serverAlias="DBYASHBET-bodb_YashBet" isFunction="0" isNested="0"></info>*/
USE bodb_YashBet
GO
ALTER PROCEDURE [dbo].[Task_API_Queue_Process]
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Import data from API_Queue

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
		
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

	-- WithdrawalInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_WithdrawalInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('WithdrawalInfo', @ErrCode, @ErrMsg)
		END
	END

	-- BonusInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_BonusInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('BonusInfo', @ErrCode, @ErrMsg)
		END
	END

	-- RebateMLog
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_RebateMLog @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('RebateMLog', @ErrCode, @ErrMsg)
		END
	END

	-- TpReport9W
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpReport9W @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpReport9W', @ErrCode, @ErrMsg)
		END
	END

	-- TpWager9W
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_TpWager9W @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('TpWager9W', @ErrCode, @ErrMsg)
		END
	END
	
	-- WeeklyBonusInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''
		EXEC dbo.Task_API_Queue_WeeklyBonusInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES ('WeeklyBonusInfo', @ErrCode, @ErrMsg)
		END
	END
	

	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX), @recipients VARCHAR(MAX)

	-- In case having error
	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053')
			SELECT @recipients = 'sophia.nguyen@starixsoft.com;pontus@starixsoft.com'
		ELSE
			SELECT @recipients = 'sophia.nguyen@starixsoft.com'

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