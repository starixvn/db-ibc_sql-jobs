/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [sb].[CustomerLog_MsgProcess_UserLog_Credit]
	@MsgType VARCHAR(200)='',	
	@log xml,
	@IsExistingTarget BIT = 0	
/*
	Create By: Johnson
	Created Date: 20181101
	Task: process message for userlog_credit [redmine: #103547]
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20181101@Johnson: create sp [redmine: #105319]
		- 20190530@Paul: Correct param name [Redmine: #113198]
*/
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @handle INT,
		@error_Message NVARCHAR(MAX),
		@message_body NVARCHAR(MAX)
		
	IF @MsgType = 'MessageType_CustomerLog_UserLog_Credit'
	BEGIN
		DECLARE @Date DATE, @log_bk XML, @SB_Error BIT
				
		SELECT @Date = CURRENT_TIMESTAMP
		
		DECLARE @tmpLog TABLE(UserID  INT,  
							  CustID INT,
							  Doing NVARCHAR(max),
							  OldValue MONEY,
							  NewValue MONEY,
							  IP VARCHAR(15),
							  ActionID INT,
							  ActualRate FLOAT,
							  logdate DATETIME)
		
		CREATE TABLE #LogOutput(
				[logid] [bigint],
				[userid] [int],
				[custid] [int],
				[logdate] [datetime],
				[OldValue] [money],
				[NewValue] [money],
				[ip] [varchar](15),
				[doing] [varchar](500),
				[ActionID] [int],
				[ActualRate] [float]
			) 
			   
		EXECUTE sys.sp_xml_preparedocument @handle OUTPUT, @log
		
		INSERT INTO @tmpLog	(UserID, 
							CustID,						 
							Doing, 
							OldValue, 
							NewValue, 
							IP, 
							ActionID,
							ActualRate,
							LogDate)
		SELECT UserID, CustID, Doing, OldValue, NewValue, IP, ActionID, 0 as ActualRate, LogDate	
		FROM OPENXML(@handle,'/Root/Row',1) 
				WITH (UserID  int,  
					  CustID int,
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
			INSERT INTO UserLog_Credit (UserID, 
									CustID,							
									Doing, 
									OldValue, 
									NewValue, 
									IP, 
									ActionID,
									ActualRate,
									LogDate,
									CreatedDate)  
			OUTPUT inserted.logid,inserted.userid,inserted.custid,inserted.logdate,inserted.OldValue,
				inserted.NewValue,inserted.ip,inserted.doing,inserted.ActionID,inserted.ActualRate
			INTO #LogOutput([logid],[userid],[custid],[logdate],[OldValue],[NewValue],[ip],[doing],[ActionID],[ActualRate])	
			SELECT UserID,
				CustID,		 
				Doing, 
				OldValue, 
				NewValue, 
				IP, 
				ActionID,
				ActualRate,
				LogDate,
				getdate()
			FROM @tmpLog
			
			IF @IsExistingTarget = 1
			BEGIN
				SET @log_bk = (SELECT [logid] as '@LogID',
									[userid] as '@UserID',
									[custid] as '@CustID',
									[logdate] as '@LogDate',
									[OldValue] as '@OldValue',
									[NewValue] as '@NewValue',
									[ip] as '@IP',
									[doing] as '@Doing',
									[ActionID] as '@ActionID',
									[ActualRate] as '@ActualRate'			
								FROM #LogOutput
								FOR XML PATH('Row')
							)
				
				EXEC sb.CustomerLog_SendMessage @xml = @log_bk, 
												@MessageType='MessageType_CustomerLog_UserLog_Credit_BK', 
												@functionName = 'UserLog_Others',
												@SB_Error = @SB_Error out	
				
				IF @SB_Error = 1
					RAISERROR (
								   'Inserted DBLog already, but can not send to DBLog_BK', -- Message text.  
								   16, -- Severity.  
								   1 -- State.  
							   );
			END
			
		END TRY
		BEGIN CATCH
			SET @error_Message = ERROR_MESSAGE()
			SET @message_body = CONVERT(VARCHAR(MAX),@log)
			
			INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
			VALUES ('UserLog_Others', @message_body, @error_Message,'UserLog_Credit','MessageType_CustomerLog_UserLog_Credit_BK',GETDATE(),0)
			
			-- Send Email to Production team for notification
			EXEC sb.EmailNotification @QueueName = 'Queue_Others',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Userlog_Others'
				
		END CATCH
	END	
	ELSE IF @MsgType = 'MessageType_CustomerLog_UserLog_Credit_BK'
	BEGIN
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
			VALUES ('UserLog_Others', @message_body, @error_Message,'UserLog_Credit','MessageType_CustomerLog_UserLog_Others_BK',GETDATE(),0)
			
			-- Send Email to Production team for notification
			EXEC sb.EmailNotification @QueueName = 'Queue_Others_BK',@message_body = @message_body,@error_message = @error_Message, @functionName = 'UserLog_Others'
			
		END CATCH
		
		EXEC sp_xml_removedocument @handle; 
	END
END
GO
	