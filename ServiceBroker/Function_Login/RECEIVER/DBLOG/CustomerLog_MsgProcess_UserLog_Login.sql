

ALTER PROCEDURE [sb].[CustomerLog_MsgProcess_UserLog_Login]
(
	@XmlMessage XML
  , @IsExistingTarget BIT
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
	
	CREATE TABLE #UserLog_Login(
		[LogID] [bigint] NOT NULL ,
		[UserID] [int] NOT NULL,
		[RoleID] [tinyint] NOT NULL,
		[SubAccID] [int] NOT NULL,
		[ServerID] [int] NOT NULL,
		[IP] [varchar](15) NOT NULL,
		[LogDate] [datetime] NULL,
		[ActionID] [int] NULL,
		[Doing] [varchar](300) NULL,
		[DomainName] [nvarchar](253) NULL,
		[BrowserName] [nvarchar](255) NULL,
		[Platform] [nvarchar](255) NULL,
		[CountryCode] [varchar](64) NULL,
		[Duration] [int] NULL,
		[username2] [varchar](50) NULL,
		[CreatedDate] [datetime] NULL
	) 

	SELECT @XmlMessage as message
	
	EXECUTE sys.sp_xml_preparedocument @_hdoc OUTPUT, @XmlMessage
	
	BEGIN TRY
		INSERT INTO	dbo.UserLog_Login(UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing, BrowserName, Platform, CountryCode, Duration, Username2, CreatedDate)   
		
		OUTPUT inserted.LogID,inserted.UserID, inserted.RoleID, inserted.SubAccID, inserted.ServerID, inserted.IP, inserted.DomainName, inserted.LogDate, inserted.ActionID, inserted.Doing, inserted.BrowserName, inserted.Platform
				, inserted.CountryCode, inserted.Duration, inserted.Username2,inserted.CreatedDate
		
		INTO #UserLog_Login(LogID, UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing,  BrowserName, Platform, CountryCode, Duration, username2,CreatedDate) 
		
		SELECT	UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing, BrowserName, Platform, CountryCode, Duration, Username2, GETDATE()
		FROM	OPENXML(@_hdoc,'/root/row', 1)   
			WITH (
				UserID		INT				'@UserID'
			,	RoleID		TINYINT			'@RoleID'
			,	SubAccID	INT				'@SubAccID'
			,	ServerID	INT				'@ServerID'
			,	IP			VARCHAR(20)		'@IP'
			,	DomainName	NVARCHAR(253)	'@DomainName'
			,	LogDate		DATETIME		'@LogDate'
			,	ActionID	INT				'@ActionID'
			,	Doing		VARCHAR(300)	'@Doing'
			,	BrowserName	NVARCHAR(255)	'@BrowserName'
			,	Platform	NVARCHAR(255) 	'@Platform'
			,	CountryCode	VARCHAR(64) 	'@CountryCode'
			,	Duration	INT 			'@Duration'
			,	Username2	VARCHAR(50)		'@Username2'
			)					
	
		IF @IsExistingTarget = 1
		BEGIN
			SET @xml_dblog_bk = (SELECT LogID AS '@LogID'
										, UserID AS '@UserID'
										, RoleID AS '@RoleID'
										, SubAccID AS '@SubAccID'
										, ServerID AS '@ServerID'
										, IP AS '@IP'
										, DomainName AS '@DomainName'
										, LogDate AS '@LogDate'
										, ActionID AS '@ActionID'
										, Doing AS '@Doing'
										, BrowserName AS '@BrowserName'
										, Platform AS '@Platform'
										, CountryCode AS '@CountryCode'
										, Duration AS '@Duration'
										, Username2 AS '@Username2'
										, CreatedDate AS '@CreatedDate'
								 FROM #UserLog_Login
								 FOR XML path('row'),root ('root')
									 )
			
			-- Send message to DBLOG_BK	
			EXEC sb.CustomerLog_SendMessage @xml = @xml_dblog_bk,@MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			
			IF @SB_Error = 1
				RAISERROR (
							   'Inserted DBLog already, but can not send to DBLog_BK', -- Message text.  
							   16, -- Severity.  
							   1 -- State.  
						   );
		END  			
		
		EXECUTE	sys.sp_xml_removedocument @_hdoc
	END TRY
	BEGIN CATCH
		SET @error_Message = ERROR_MESSAGE()
		SET @message_body = CONVERT(VARCHAR(MAX),@XmlMessage)
		
		INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
		VALUES ('Login', @message_body, @error_Message,'UserLog_Login','MessageType_CustomerLog_UserLog_Login',GETDATE(),0)
		
		-- Send Email to Production team for notification
		EXEC sb.EmailNotification @QueueName = 'Queue_DBLOG',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Login'
		
		EXECUTE	sys.sp_xml_removedocument @_hdoc		
	END CATCH			
	
	SET NOCOUNT OFF
	
	
END	

