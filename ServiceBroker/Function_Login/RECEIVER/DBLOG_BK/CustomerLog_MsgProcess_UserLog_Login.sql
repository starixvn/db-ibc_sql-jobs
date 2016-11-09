ALTER PROCEDURE sb.CustomerLog_MsgProcess_UserLog_Login
(
	@XmlMessage XML
)

/*
	Created By: Helen
	Created Date: 20161027
	Task: Apply Service Broker for login function
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
	
	DECLARE @_hdoc INT, @error_Message VARCHAR(MAX), @message_body VARCHAR(MAX)
	
	EXECUTE sys.sp_xml_preparedocument @_hdoc OUTPUT, @XmlMessage
	
	--SELECT @XmlMessage AS message_processed
	
	SELECT	LogID,UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing, BrowserName, Platform, CountryCode, Duration, Username2, CreatedDate
	FROM	OPENXML(@_hdoc,'/root/row', 1)   
		WITH (
			LogID		BIGINT			'@LogID'
		,	UserID		INT				'@UserID'
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
		,	CreatedDate	DATETIME		'@CreatedDate'
		)
		
	BEGIN TRY
		INSERT INTO	dbo.UserLog_Login(LogID,UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing, BrowserName, Platform, CountryCode, Duration, Username2, CreatedDate)   
		SELECT	LogID,UserID, RoleID, SubAccID, ServerID, IP, DomainName, LogDate, ActionID, Doing, BrowserName, Platform, CountryCode, Duration, Username2, CreatedDate
		FROM	OPENXML(@_hdoc,'/root/row', 1)   
			WITH (
				LogID		BIGINT			'@LogID'
			,	UserID		INT				'@UserID'
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
			,	CreatedDate	DATETIME		'@CreatedDate'
			)
			
	 
	END TRY
	BEGIN CATCH
	
		SET @error_Message = ERROR_MESSAGE()
		SET @message_body = CONVERT(VARCHAR(MAX),@XmlMessage)
		
		INSERT INTO sb.FailedMessageMonitoring([FunctionName], [Message],[ErrorMessage],[TableName],[MessageType],[CreatedDate],[IsResolved])
		VALUES ('Login', @message_body, @error_Message,'UserLog_Login','MessageType_CustomerLog_UserLog_Login',GETDATE(),0)
		
		-- Send Email to Production team for notification
		EXEC sb.EmailNotification @QueueName = 'Queue_DBLOG_BK',@message_body = @message_body,@error_message = @error_Message, @functionName = 'Login'
		
	END CATCH	
	
	EXECUTE	sys.sp_xml_removedocument @_hdoc
	
	SET NOCOUNT OFF
	
END	
GO



