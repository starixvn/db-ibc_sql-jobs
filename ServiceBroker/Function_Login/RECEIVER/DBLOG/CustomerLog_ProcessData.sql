ALTER PROCEDURE [sb].[CustomerLog_ProcessData]
AS
/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
*/
BEGIN
	DECLARE @xml_externalNap XML, @xml_Alpha XML, @xml_RMS XML
	
	DECLARE @handle UNIQUEIDENTIFIER
	
	DECLARE @i INT, @countDeleted INT
	
	DECLARE @ReceiveMax INT, @timeout INT, @IsExistingTarget BIT
	
	DECLARE @message_type_name NVARCHAR(256)
	
	SELECT TOP 1 @ReceiveMax = ISNULL(MaxReceiveMsg, 1)
			   , @timeout = ISNULL(MaxReceiveTimeOut, 0)
			   , @IsExistingTarget = ISNULL(IsExistingTarget, 0)
	FROM sb.ConfigurationReference	WITH (NOLOCK) 
	WHERE FunctionName = 'Login'	
	
	DECLARE @Messages TABLE (conversation_handle UNIQUEIDENTIFIER, message_type_name NVARCHAR(256), message_body XML)
	DECLARE @EndDialogMessages TABLE 
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY, 
		conversation_handle UNIQUEIDENTIFIER, 
		message_type_name NVARCHAR(256), 
		message_body XML
	)
	 
	WAITFOR (RECEIVE TOP (@ReceiveMax)
					conversation_handle,
					message_type_name, 
					message_body
			FROM queue_DBLOG
			INTO @Messages ), TIMEOUT @timeout;
			
	IF (@@ROWCOUNT = 0)
		RETURN
		
	-- filter http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog and http://schemas.microsoft.com/SQL/ServiceBroker/Error 					
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
		SELECT TOP 1 @handle = conversation_handle
		FROM @EndDialogMessages
		
		END CONVERSATION @handle WITH CLEANUP;
	END			
	
	SELECT TOP 1 
		   @handle = conversation_handle
		 , @message_type_name = message_type_name
	FROM @Messages						  						  
	
	IF @message_type_name = 'MessageType_CustomerLog_UserLog_Login'
	BEGIN
		SET @xml_Alpha = (SELECT message_body AS 'node()'
						  FROM @Messages					
						  FOR XML PATH (''), ROOT)
					
		--Debug: PRINT 'UserLog_Login' + CONVERT(VARCHAR(MAX),@xml_Alpha)
		EXEC [sb].[CustomerLog_MsgProcess_UserLog_Login] @XmlMessage = @xml_Alpha
													   , @IsExistingTarget = @IsExistingTarget
	END
	ELSE IF @message_type_name = 'MessageType_CustomerLog_eaUserLog_Login'
	BEGIN			
		SET @xml_externalNap = (SELECT message_body AS 'node()'
								FROM @Messages					
								FOR XML PATH (''), ROOT)
					
		--Debug: PRINT 'eaUserLog_Login'  + CONVERT(VARCHAR(MAX),@xml_externalNap)
		EXEC [sb].[CustomerLog_MsgProcess_eaUserLog_Login] @XmlMessage = @xml_externalNap
														 , @IsExistingTarget = @IsExistingTarget
	END
	--ELSE IF @message_type_name = 'MessageType_CustomerLog_rmUserLog_Login'
	--BEGIN
	--	SET @xml_RMS = (SELECT message_body AS 'node()'
	--					FROM @Messages					
	--					FOR XML PATH (''), ROOT)
					
	--	--Debug: PRINT 'rmUserLog_Login'  + CONVERT(VARCHAR(MAX),@xml_RMS)
	--	EXEC [sb].[CustomerLog_MsgProcess_rmUserLog_Login] @XmlMessage = @xml_RMS
	--													 , @IsExistingTarget = @IsExistingTarget
	--END			
END