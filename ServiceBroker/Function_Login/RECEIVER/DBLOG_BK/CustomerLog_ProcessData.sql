ALTER PROCEDURE [sb].[CustomerLog_ProcessData]
AS
/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBLOG_BK/bodb_CustomerLog
	
	Para's explaination
*/
BEGIN
	DECLARE @xml_externalNap XML, @xml XML, @MessageType VARCHAR(200)
	
	DECLARE @handle UNIQUEIDENTIFIER
	
	DECLARE @i INT, @countDeleted INT
	
	DECLARE @ReceiveMax INT, @timeout INT
	
	SELECT @timeout = MaxReceiveTimeOut
	FROM sb.ConfigurationReference	WITH (NOLOCK) 
	WHERE FunctionName = 'Login'
		
	DECLARE @EndDialogMessages TABLE 
	(
		ID INT IDENTITY(1, 1) PRIMARY KEY, 
		conversation_handle UNIQUEIDENTIFIER, 
		message_type_name NVARCHAR(256), 
		message_body XML
	)
	 
	WAITFOR (RECEIVE TOP (1) @handle = conversation_handle,
					@MessageType = message_type_name, 
					@xml = message_body
			FROM queue_DBLOG_BK ), TIMEOUT @timeout;
			
	IF (@@ROWCOUNT = 0)
		RETURN
	
	-- WHEN CONVERSATION IS ENDED AT INITIATOR	
	-- filter http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog and http://schemas.microsoft.com/SQL/ServiceBroker/Error 					
	IF @MessageType IN ('http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
					  , 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
	BEGIN					  
		END CONVERSATION @handle WITH CLEANUP;						  						  	
	END
	ELSE IF @MessageType = 'MessageType_CustomerLog_UserLog_Login' -- Alpha
	BEGIN
		EXEC [sb].[CustomerLog_MsgProcess_UserLog_Login] @xml
	END
	ELSE IF @MessageType = 'MessageType_CustomerLog_eaUserLog_Login' -- External Nap
	BEGIN
		EXEC [sb].[CustomerLog_MsgProcess_eaUserLog_Login] @xml
	END
	ELSE IF @MessageType = 'MessageType_CustomerLog_rmUserLog_Login' -- RMS
	BEGIN
		EXEC [sb].[CustomerLog_MsgProcess_rmUserLog_Login] @xml
	END
	
END

