/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [Task_SendEmailNotificationLogCredit]	
/*
	Created Date: 20231214@Johnson
	Task:Scan log Credit FailedMessageMonitoring to send email Notification [redmine: #196720]
	DB: DBLOG/bodb_CustomerLog
	
	Parameter's explaination
	
	Revision:
		- 20231214@Johnson: initial sp [redmine: #196720]
*/
AS
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @error_Message VARCHAR(MAX),
		@message_body VARCHAR(MAX),
		@ID INT
		
	WHILE(1=1)
	BEGIN
		SELECT TOP (1) @message_body = Message
			,@error_message = ErrorMessage
			,@ID = ID
		FROM sb.FailedMessageMonitoring WITH(NOLOCK)
		WHERE IsSentMail = 0
			AND TableName = 'UserLog_Credit'
			AND FunctionName = 'Userlog_Others'
		ORDER BY ID ASC
		
		IF @@ROWCOUNT = 0
			BREAK;
			
		-- Send Email to Production team for notification
		EXEC sb.EmailNotification @QueueName = 'Queue_Others',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Userlog_Others'
		
		UPDATE sb.FailedMessageMonitoring WITH(ROWLOCK)
		SET IsSentMail = 1
		WHERE ID = @ID
	END	
	
END