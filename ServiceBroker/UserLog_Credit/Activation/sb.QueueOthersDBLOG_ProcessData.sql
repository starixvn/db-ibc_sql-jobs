/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [sb].[QueueOthersDBLOG_ProcessData]
AS
/*
	Create By: Johnson
	Created Date: 20181114
	Task: activation procedure for service broker for userlog_credit [redmine: #103547]
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20181114@Johnson: create sp [redmine: #105319]
*/
BEGIN
	DECLARE @log xml 
	
	DECLARE @handle UNIQUEIDENTIFIER
			,@countDeleted INT
			,@ReceiveMax INT
			,@timeout INT
			,@IsExistingTarget BIT
			,@message_type_name NVARCHAR(256)
	
	SELECT TOP 1 @ReceiveMax = ISNULL(MaxReceiveMsg, 1)
			   , @timeout = ISNULL(MaxReceiveTimeOut, 0)
			   , @IsExistingTarget = ISNULL(IsExistingTarget, 0)
	FROM sb.ConfigurationReference	WITH (NOLOCK) 
	WHERE FunctionName = 'UserLog_Others'	
	
	DECLARE @Messages TABLE (conversation_handle UNIQUEIDENTIFIER, 
							message_type_name NVARCHAR(256), 
							message_body XML)
	
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
			FROM dbo.Queue_Others
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
	
	IF @message_type_name = 'MessageType_CustomerLog_UserLog_Credit'
	BEGIN
		SET @log = (SELECT message_body AS 'node()'
				  FROM @Messages					
				   FOR XML PATH (''), ROOT ('Root'))
			
		EXEC [sb].[CustomerLog_MsgProcess_UserLog_Credit] @log = @log, 
														  @IsExistingTarget= @IsExistingTarget
	END
			
END
GO