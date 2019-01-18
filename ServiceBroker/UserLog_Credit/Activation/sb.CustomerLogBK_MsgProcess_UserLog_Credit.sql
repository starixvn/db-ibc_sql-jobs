ALTER PROCEDURE [sb].[CustomerLogBK_MsgProcess_UserLog_Credit]
	@log xml
/*
	Create By: Johnson
	Created Date: 20181114
	Task: process message for userlog_credit [redmine: #103547]
	DB: DBLOGBK/bodb_CustomerLog
	
	Parameter's explaination
	
	Revision:
	
*/
AS
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @handle INT,
		@error_Message NVARCHAR(MAX),
		@message_body NVARCHAR(MAX)
		
	EXECUTE sys.sp_xml_preparedocument @handle OUTPUT, @log
	
	BEGIN TRY	
		SET IDENTITY_INSERT dbo.UserLog_Credit ON
		
		INSERT INTO [dbo].[UserLog_Credit]
			   ([LogID]
			   ,[userid]
			   ,[custid]
			   ,[logdate]           
			   ,[OldValue]
			   ,[NewValue]
			   ,[ip]
			   ,[doing]
			   ,[ActionID]
			   ,[ActualRate]
			   ,[CreatedDate])
		SELECT LogID,UserID, CustID, logdate,OldValue, NewValue, IP, Doing, ActionID,ActualRate, getdate()	
		FROM OPENXML(@handle,'/Root/Row',1) 
				WITH (LogID INT,
					UserID  int,
					CustID int,
					LogDate DATETIME,
					OldValue money,
					NewValue money,
					IP VARCHAR(15),
					Doing nvarchar(max),
					ActionID int,
					ActualRate FLOAT
					); 
		SET IDENTITY_INSERT dbo.UserLog_Credit OFF			
	END TRY
	BEGIN CATCH
		SET @error_Message = ERROR_MESSAGE()
		SET @message_body = CONVERT(VARCHAR(MAX),@log)
		
		INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
		VALUES ('UserLog_Others', @message_body, @error_Message,'UserLog_Others','MessageType_CustomerLog_UserLog_Others',GETDATE(),0)
		
		-- Send Email to Production team for notification
		EXEC sb.EmailNotification @QueueName = 'Queue_Others_BK',@message_body = @message_body,@error_message = @error_Message, @funtionName = 'UserLog_Others'
		
	END CATCH
	
	EXEC sp_xml_removedocument @handle; 
END
GO
	