/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_Queue_ProcessCorrectData]
AS

/*
	Created: 20230418@Evan
	DB: DBN88-bodb_N88
	Task: Get data from API_QueueTest to correct data API_Queue 

	Revisions:
		- 20230418@Evan: Initialize SP [RedmineID: #183319]
		
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(2000), @BatchSize INT, @CheckInTime DATETIME,@DataSource VARCHAR(200);
	DECLARE @ErrTable TABLE (DataSource VARCHAR(200), ErrCode INT, ErrMsg NVARCHAR(2000))
	DECLARE @QueueTable TABLE (QueueId BIGINT, XmlData XML, LogDesc VARCHAR(2000), DataSource VARCHAR(200))

	SELECT @BatchSize = SValue FROM SystemSettingsTest WITH(NOLOCK) WHERE SName = 'BatchSize'

	-- DepositInfo 
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = '', @CheckInTime = GETDATE(), @DataSource = 'CorrectDepositInfo'

		INSERT INTO @QueueTable (QueueId,XmlData,LogDesc,DataSource)
		SELECT TOP(@BatchSize) QueueId,XmlData,LogDesc,DataSource
		FROM API_QueueTest WITH(NOLOCK) 
		WHERE DataSource = 'DepositInfo' AND IsFinished = 0 

		INSERT INTO API_Queue(CheckInTime,IsFinished,XmlData,DataSource,LogDesc)
		SELECT @CheckInTime,0,XmlData,@DataSource,LogDesc
		FROM @QueueTable  
		WHERE DataSource = 'DepositInfo'

		EXEC dbo.Task_API_Queue_Correct_DepositInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES (@DataSource, @ErrCode, @ErrMsg)
		END
	END

	--WithdrawalInfo
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = '', @CheckInTime = GETDATE(), @DataSource = 'CorrectWithdrawalInfo'

		INSERT INTO @QueueTable (QueueId,XmlData,LogDesc,DataSource)
		SELECT TOP(@BatchSize) QueueId,XmlData,LogDesc,DataSource
		FROM API_QueueTest WITH(NOLOCK) 
		WHERE DataSource = 'WithdrawalInfo' AND IsFinished = 0 

		INSERT INTO API_Queue(CheckInTime,IsFinished,XmlData,DataSource,LogDesc)
		SELECT @CheckInTime,0,XmlData,@DataSource,LogDesc
		FROM @QueueTable  
		WHERE DataSource = 'WithdrawalInfo'

		EXEC dbo.Task_API_Queue_Correct_WithdrawalInfo @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrTable (DataSource, ErrCode, ErrMsg)
			VALUES (@DataSource, @ErrCode, @ErrMsg)
		END
	END

	-- In case having error
	DECLARE @Subject VARCHAR(1000) = '', @Msg NVARCHAR(MAX), @recipients VARCHAR(MAX)

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053')
			SELECT @recipients = 'sophia.nguyen@starixvn.com;pontus@starixvn.com'
		ELSE
			SELECT @recipients = 'sophia.nguyen@starixvn.com'

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

