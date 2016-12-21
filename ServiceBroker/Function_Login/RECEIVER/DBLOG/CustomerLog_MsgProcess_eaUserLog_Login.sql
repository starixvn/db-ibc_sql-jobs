ALTER PROCEDURE [sb].[CustomerLog_MsgProcess_eaUserLog_Login]
(
	@XmlMessage XML
)

/*
	Created By: Helen
	Created Date: 20161027
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB:DBLOG/bodb_CustomerLog
	-- For testing
	DECLARE @XmlData XML = '<root>
							<row LogID="76" UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.112" LogDate="2012-04-16T09:32:18.123" ActionID="1310" Doing="Account:12BETRMB01 - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 3.6" Platform="Windows NT" CountryCode="-" Duration="423" />
							<row LogID="398" UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.114" LogDate="2012-04-16T11:09:20.753" ActionID="1310" Doing="Account:hi - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 11.0" Platform="Windows NT" CountryCode="-" Duration="0" />
							</root>';

*/
AS
BEGIN
 
	SET NOCOUNT ON
	
	DECLARE @_hdoc INT, @xml_dblog_bk XML, @SB_Error BIT = 0, @error_Message VARCHAR(MAX), @message_body VARCHAR(MAX)
	
	SELECT @XmlMessage AS MESSAGE
	
	CREATE TABLE #eaUserLog_Login(
		[LogID] [bigint],
		[UserID] [int] NOT NULL,
		[IP] [varchar](50) NOT NULL,
		[LogDate] [datetime] NULL,
		[ActionID] [int] NULL,
		[TrackingValue] [nvarchar](300) NULL,
		[DomainName] [varchar](256) NULL,
		[BrowserName] [varchar](256) NULL,
		[Platform] [varchar](256) NULL,
		[CountryCode] [varchar](50) NULL,
		[Duration] [int] NULL,
		[CreatedDate] [datetime] NULL
	)

	EXECUTE sys.sp_xml_preparedocument @_hdoc OUTPUT, @XmlMessage
	
	BEGIN TRY
	
		INSERT INTO [dbo].[eaUserLog_Login]([UserID],[IP],[LogDate],[ActionID],[TrackingValue],[DomainName],[BrowserName],[Platform],[CountryCode],[Duration], [CreatedDate])    
		OUTPUT inserted.LogID,inserted.[UserID],inserted.[IP],inserted.[LogDate],inserted.[ActionID],inserted.[TrackingValue],inserted.[DomainName]
				,inserted.[BrowserName],inserted.[Platform],inserted.[CountryCode],inserted.[Duration],inserted.[CreatedDate]
		
		INTO #eaUserLog_Login([LogID],[UserID],[IP],[LogDate],[ActionID],[TrackingValue],[DomainName],[BrowserName],[Platform],[CountryCode],[Duration],[CreatedDate]) 
					
		SELECT  [UserID],[IP],[LogDate],[ActionID],[TrackingValue],[DomainName],[BrowserName],[Platform],[CountryCode],[Duration], GETDATE() AS [CreatedDate]      
		FROM OPENXML(@_hdoc,'/root/row', 1)   
			WITH (UserID		INT '@UserID',
				IP			VARCHAR(50) '@IP',
				LogDate		DATETIME '@LogDate',
				ActionID	INT '@ActionID',
				TrackingValue NVARCHAR(300) '@TrackingValue',
				DomainName VARCHAR(256) '@DomainName',
				BrowserName VARCHAR(256) '@BrowserName',
				Platform VARCHAR(256) '@Platform',
				CountryCode VARCHAR(50) '@CountryCode',
				Duration INT '@Duration'
				)
		
		SET @xml_dblog_bk = (SELECT [LogID] AS '@LogID',[UserID] AS '@UserID',[IP] AS '@IP',[LogDate] AS '@LogDate'
									,[ActionID] '@ActionID',[TrackingValue] '@TrackingValue',[DomainName] AS '@DomainName',[BrowserName] AS '@BrowserName',[Platform] AS '@Platform'
									,[CountryCode] AS '@CountryCode',[Duration] AS '@Duration'
									, [CreatedDate] AS '@CreatedDate'
							 FROM #eaUserLog_Login
							 FOR XML path('row'),root ('root')
							 )
		-- Send message to DBLOG_BK		
		EXEC sb.CustomerLog_SendMessage @xml = @xml_dblog_bk,@MessageType='MessageType_CustomerLog_eaUserLog_Login', @SB_Error = @SB_Error out					 				
	
		IF @SB_Error = 1
			RAISERROR (
						   'Inserted DBLog already, but can not send to DBLog_BK', -- Message text.  
						   16, -- Severity.  
						   1 -- State.  
					   );
	
		EXECUTE	sys.sp_xml_removedocument @_hdoc
	END TRY
	BEGIN CATCH
		
		SET @error_Message = ERROR_MESSAGE()
		SET @message_body = CONVERT(VARCHAR(MAX),@XmlMessage)
		
		INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
		VALUES ('Login', @message_body, @error_Message,'eaUserLog_Login','MessageType_CustomerLog_eaUserLog_Login',GETDATE(),0)
		
		-- Send Email to Production team for notification
		EXEC sb.EmailNotification @QueueName = 'Queue_DBLOG',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Login'
		
		EXECUTE	sys.sp_xml_removedocument @_hdoc		
	END CATCH				

	SET NOCOUNT OFF
	
END	
