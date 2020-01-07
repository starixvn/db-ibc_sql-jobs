/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [sb].[CustomerLog_MsgProcess_CS_UserLog_Credit]
	@MsgType VARCHAR(200)='',	
	@log xml,
	@IsExistingTarget BIT = 0	
/*
	Created By: Paul
	Created Date: 20190530
	Task: CN88 Log [Redmine: #113198]
	DB:DBLOG/bodb_CustomerLog

	Revision:
		- 20190530@Paul: Initial SP [Redmine: #113198]
*/
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @handle INT,
		@error_Message NVARCHAR(MAX),
		@message_body NVARCHAR(MAX)
		
	IF @MsgType = 'MessageType_CustomerLog_CS_UserLog_Credit'
	BEGIN
		DECLARE @Date DATE, @SB_Error BIT
				
		SELECT @Date = CURRENT_TIMESTAMP
		
		DECLARE @tmpLog TABLE(UserID  INT,  
							  CustID INT,
							  SubAccID INT,
							  LogDate DATETIME,
							  OldValue MONEY,
							  NewValue MONEY,
							  IP VARCHAR(15),
							  Doing VARCHAR(500),
							  ActionID INT,
							  ActualRate FLOAT)
			   
		EXECUTE sys.sp_xml_preparedocument @handle OUTPUT, @log
		
		INSERT INTO @tmpLog	(UserID, 
							CustID,	
							SubAccID,					 
							Doing, 
							OldValue, 
							NewValue, 
							IP, 
							ActionID,
							ActualRate,
							LogDate)
		SELECT UserID, CustID, SubAccID, Doing, OldValue, NewValue, IP, ActionID, 0 as ActualRate, LogDate	
		FROM OPENXML(@handle,'/root/row',1) 
				WITH (UserID  int,  
					  CustID int,
					  SubAccID INT,
					  Doing nvarchar(max),
					  OldValue money,
					  NewValue money,
					  IP VARCHAR(15),
					  ActionID int,
					  LogDate DATETIME
					  ); 
		
		EXEC sp_xml_removedocument @handle; 
		
		UPDATE t
		SET t.ActualRate = e.ActualRate
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			INNER JOIN @tmpLog t ON c.custid = t.custid
			INNER JOIN bodb02.dbo.ExchangeDailyOanda e WITH (NOLOCK) ON c.Currency = e.ExchangeId
		WHERE ExchangeDate = @Date
		
		BEGIN TRY	
			INSERT INTO CS_UserLog_Credit (
				UserID,
				CustID,
				SubAccID,
				LogDate,
				OldValue,
				NewValue,
				IP,
				Doing,
				ActionID,
				ActualRate,
				CreatedDate
			)  
			SELECT	UserID,
					CustID,
					SubAccID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					ActionID,
					ActualRate,
					GETDATE()
			FROM @tmpLog
		END TRY
		BEGIN CATCH
			SET @error_Message = ERROR_MESSAGE()
			SET @message_body = CONVERT(VARCHAR(MAX),@log)
			
			INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
			VALUES ('UserLog_Others', @message_body, @error_Message,'CS_UserLog_Credit','MessageType_CustomerLog_CS_UserLog_Credit',GETDATE(),0)
			
			-- Send Email to Production team for notification
			EXEC sb.EmailNotification @QueueName = 'Queue_Others',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Userlog_Others'
				
		END CATCH
	END	
END
GO
	