ALTER PROCEDURE [sb].[CustomerLog_ProcessData]
AS
/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBLOG/bodb_CustomerLog & DBLOG_BK/bodb_CustomerLog & 
	
	Para's explaination
*/
BEGIN
	DECLARE @xml_externalNap XML, @xml_Alpha XML, @xml_RMS XML
	
	DECLARE @handle UNIQUEIDENTIFIER
	
	DECLARE @i INT, @countDeleted INT
	
	DECLARE @ReceiveMax INT, @timeout INT
	
	SELECT @ReceiveMax = MaxReceiveMsg, @timeout = MaxReceiveTimeOut
	FROM sb.ConfigurationReference	WITH (NOLOCK) 
	WHERE FunctionName = 'Login'
	
	--SELECT @xml = NULL, @handle = NULL
	
	DECLARE @Messages TABLE (conversation_handle UNIQUEIDENTIFIER, message_type_name NVARCHAR(256), message_body XML)
	DECLARE @EndDialogMessages TABLE 
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY, 
		conversation_handle UNIQUEIDENTIFIER, 
		message_type_name NVARCHAR(256), 
		message_body XML
	)
	 
	WAITFOR (RECEIVE TOP (@ReceiveMax)conversation_handle,
					message_type_name, 
					message_body
			FROM queue_DBLOG
			INTO @Messages ), TIMEOUT @timeout;
			
	IF (@@ROWCOUNT = 0)
		RETURN
		
	-- code here: to filter http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog and http://schemas.microsoft.com/SQL/ServiceBroker/Error 					
	DELETE FROM @Messages
	OUTPUT DELETED.conversation_handle
		 , DELETED.message_type_name
		 , DELETED.message_body	
			INTO @EndDialogMessages
	WHERE message_type_name IN ('http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
							  , 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')							  
	
	SET @countDeleted = @@ROWCOUNT
	
	IF @countDeleted > 0
	BEGIN
		SET @i = 1
		
		WHILE @i <= @countDeleted
		BEGIN
			SELECT @handle = conversation_handle
			FROM @EndDialogMessages
			WHERE ID = @i;
			
			END CONVERSATION @handle WITH CLEANUP;
			
			SET @i = @i + 1;
		END
	END							  						  
	
	SET @xml_Alpha = (SELECT message_body AS 'node()'
				FROM @Messages
				WHERE message_type_name = 'MessageType_CustomerLog_UserLog_Login'
				FOR XML PATH (''), ROOT)
				
	SET @xml_externalNap = (SELECT message_body AS 'node()'
				FROM @Messages
				WHERE message_type_name = 'MessageType_CustomerLog_eaUserLog_Login'
				FOR XML PATH (''), ROOT)
	
	SET @xml_RMS = (SELECT message_body AS 'node()'
				FROM @Messages
				WHERE message_type_name = 'MessageType_CustomerLog_rmUserLog_Login'
				FOR XML PATH (''), ROOT)
							
	
	IF @xml_Alpha IS NOT NULL
	BEGIN
		--Debug: PRINT 'UserLog_Login' + CONVERT(VARCHAR(MAX),@xml_Alpha)
		EXEC [sb].[CustomerLog_MsgProcess_UserLog_Login] @xml_Alpha
	END	 	
	
	IF @xml_externalNap IS NOT NULL
	BEGIN
		--Debug: PRINT 'eaUserLog_Login'  + CONVERT(VARCHAR(MAX),@xml_externalNap)
		EXEC [sb].[CustomerLog_MsgProcess_eaUserLog_Login] @xml_externalNap
	END
	
	IF @xml_RMS IS NOT NULL
	BEGIN
		--Debug: PRINT 'rmUserLog_Login'  + CONVERT(VARCHAR(MAX),@xml_RMS)
		EXEC [sb].[CustomerLog_MsgProcess_rmUserLog_Login] @xml_RMS
	END
	
	
END

