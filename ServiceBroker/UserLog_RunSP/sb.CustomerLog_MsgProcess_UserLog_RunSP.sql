/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbLicenseeNet,bodbAdminNet,Dot_Member" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [sb].[CustomerLog_MsgProcess_UserLog_RunSP]
	@MsgType VARCHAR(200)='',	
	@log xml = NULL,
	@IsExistingTarget BIT = 0	
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20200903@Helen: process message for userlog_RunSP [redmine: #139238]
		
*/
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @handle INT,
		@error_Message NVARCHAR(MAX),
		@message_body NVARCHAR(MAX)
		
	IF @MsgType = 'MessageType_CustomerLog_UserLog_RunSP'
	BEGIN
		DECLARE @Date DATE, @SB_Error BIT
				
		SELECT @Date = CURRENT_TIMESTAMP
		
		DECLARE @tmpLog TABLE(UserID  INT,  
							  CustID INT,
							  SPName VARCHAR(50),
							  TrackingValue VARCHAR(MAX),
							  TrackingValue2 VARCHAR(MAX),
							  ActionID INT,
							  Duration INT,
							  logdate DATETIME,
							  Isfinished BIT
							  )
		
		DECLARE @tmpLog_batch TABLE(UserID  INT,  
							  CustID INT,
							  SPName VARCHAR(50),
							  TrackingValue VARCHAR(MAX),
							  TrackingValue2 VARCHAR(MAX),
							  ActionID INT,
							  Duration INT,
							  logdate DATETIME
							  )					  
		
		EXECUTE sys.sp_xml_preparedocument @handle OUTPUT, @log
		
		INSERT INTO @tmpLog	(UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration,LogDate)
		SELECT UserID, CustID,  ActionID, TrackingValue, TrackingValue2, Duration, LogDate	
		FROM OPENXML(@handle,'/Root/Row',1) 
				WITH (UserID  int,  
					  CustID int,
					  ActionID INT,
					  TrackingValue NVARCHAR(MAX),
					  TrackingValue2 NVARCHAR(MAX),
					  Duration INT,
					  LogDate DATETIME
					  ); 
		--SELECT '@tmpLog'
		--SELECT * FROM @tmpLog
		EXEC sp_xml_removedocument @handle; 
		
		BEGIN TRY
				WHILE (1=1)
				BEGIN	
					DELETE @tmpLog_batch
					
					UPDATE TOP (2000) t
						SET Isfinished = 1
					OUTPUT deleted.UserID, deleted.CustID,  deleted.ActionID, deleted.TrackingValue, deleted.TrackingValue2, deleted.Duration, deleted.LogDate
					INTO @tmpLog_batch(UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration,LogDate)	
					FROM @tmpLog t
					WHERE t.Isfinished IS NULL
			
					IF @@ROWCOUNT = 0 BREAK
					
					INSERT INTO dbo.UserLog_RunSP (UserID, CustID, SPName, Doing, ActionID, TrackingValue, TrackingValue2, Duration,LogDate,CreatedDate)
					SELECT UserID, CustID, NULL, NULL, ActionID, TrackingValue, TrackingValue2, Duration,LogDate,GETDATE()
					FROM @tmpLog_batch
					
					WAITFOR DELAY '00:00:0.100'
					
				END	
		END TRY
		BEGIN CATCH
			SET @error_Message = ERROR_MESSAGE()
			SET @message_body = CONVERT(VARCHAR(MAX),@log)
			
			INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
			VALUES ('UserLog_Others', @message_body, @error_Message,'UserLog_RunSP','MessageType_CustomerLog_UserLog_RunSP',GETDATE(),0)
			
			-- Send Email to Production team for notification
			EXEC sb.EmailNotification @QueueName = 'Queue_Others',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Userlog_Others'
				
		END CATCH
	END	
	
END

GO


