/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROC sb.EmailNotification
(
	@QueueName VARCHAR (200) = 'Queue_DBLOG'
	, @message_body VARCHAR(MAX)
	, @error_message VARCHAR(MAX)
	, @functionName VARCHAR(200) = 'Login'
)
AS
/*
	Created By: Helen
	Created Date: 20161027
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBLOG/bodb_CustomerLog; DBLOG_BK (DB054)/bodb_CustomerLog
	
	Revision:
		- 20161027@Helen: Apply Service Broker for Writing Log [Redmine: #65806]
		- 20190530@Paul: Correct param name [Redmine: #113198]
*/
BEGIN

	DECLARE @body VARCHAR(MAX)
			,@profile_name SYSNAME
			,@subject VARCHAR(100)
			,@qstatus VARCHAR(20)				
	
	SET @error_message = ERROR_MESSAGE()
	
	SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile
	
	SELECT	@qstatus = CASE WHEN is_enqueue_enabled = 1 THEN 'enabled' ELSE 'disabled!!!' END						
	FROM sys.service_queues WITH (NOLOCK)
	WHERE name = @queueName

	SET @subject = 'CRITICAL: ' + @@SERVERNAME + ' - Service broker problem notification'

	SET @body = 'Hi There,
				Funtion Name: ' + @functionName + '
				Queue status: ' + @qstatus + '
				ERROR: ' + @error_message + ' 
				
				/* Login function:
					SELECT TOP(5) * FROM sb.FailedMessageMonitoring WITH(NOLOCK) ORDER BY CreatedDate DESC 
				*/
			'
	IF @@SERVERNAME IN ('DBCUST','SITDBCUST')
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail
			@recipients=N'dbaadmin@starixsoft.com',
			@body=@body,
			@sensitivity ='Personal',
			@importance ='High',
			--@copy_recipients ='lukas.luu@starixsoft.com',
			@subject =@subject,
			@profile_name =@profile_name;
	END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail
			@recipients=N'elodie.ho@starixsoft.com',
			@body=@body,
			@sensitivity ='Personal',
			@importance ='High',
			--@copy_recipients ='lukas.luu@starixsoft.com',
			@subject =@subject,
			@profile_name =@profile_name;
	END
END		