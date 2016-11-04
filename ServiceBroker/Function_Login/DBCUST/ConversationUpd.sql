ALTER PROC [Sb].[ConversationUpd]
( 
	@functionName VARCHAR(100)
  , @newCnt INT
  , @fromService VARCHAR(100)
  , @toService VARCHAR(100)
  , @contractName VARCHAR(100)
)
AS
/*
	Create By: Kent
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBCUST/CUSTDB; DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	/*
	--Login function
		EXEC [Sb].[ConversationUpd] @functionName = 'Login', @newCnt = 20, @fromService = 'Service_CustomerLog_DBCUST', @toService = 'Service_CustomerLog_DBLOG', @contractName = 'Contract_CustomerLog'
		
		SELECT * FROM sb.ConversationCount (NOLOCK)
		SELECT * FROM sb.ConversationManagement (NOLOCK)
		
		SELECT s.name, e.far_service, e.is_initiator
			 , e.conversation_handle, e.conversation_id
			 , e.conversation_group_id, e.state, e.state_desc
			 , e.send_sequence
			 , e.system_sequence
		from sys.conversation_endpoints e WITH(NOLOCK)
			inner join sys.services s WITH(NOLOCK) on e.service_id = s.service_id
			 
			 
		TRUNCATE TABLE sb.ConversationManagement
		truncate table sb.ConversationCount
		
		exec [Sb].[ConversationDel] @functionName = 'Login'
		
		END CONVERSATION 'E47E7873-E99C-E611-940D-002590D55490' WITH CLEANUP
		
		select * from queue_DBLOG

/*
RECEIVE CONVERT(NVARCHAR(MAX), message_body) AS Message
from queue_DBLOG
*/
-- 185152
select count(*) from dbo.UserLog_Login (nolock)
-- 185320
select MAX(logid) from dbo.UserLog_Login(nolock)

select top 10 * from dblog.bodb_CustomerLog.dbo.UserLog_Login with (nolock) 
where createdDate is not null
order by logdate desc

select * from queue_dblog
exec [sb].CustomerLog_ProcessData

delete UserLog_Login_ServiceBroker where logid > 185320

select count(*) from UserLog_Login_ServiceBroker (nolock) where logid > 185320
	--	
	*/
*/
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @Cnt INT
		  , @i INT
		  , @handle UNIQUEIDENTIFIER
		  , @sql VARCHAR(MAX)
		  , @paramDefinition VARCHAR(MAX)
		  , @CurrentDate DATETIME
			  
	SET @Cnt = (SELECT Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName)
	
	IF @Cnt IS NULL 
	BEGIN
		INSERT INTO sb.ConversationCount (functionName,Cnt) VALUES (@functionName,@newCnt)
	END
	
	SET @Cnt = ISNULL(@Cnt,0)
	SET @CurrentDate =  GETDATE()
	-- create new conversations
	IF @newCnt > @Cnt 
	BEGIN
		/*
			SELECT @sql = 
					   'BEGIN DIALOG CONVERSATION @handle
						FROM SERVICE ' + @fromService + '
						TO SERVICE ''' + @toService + '''
						on contract ' + @contractName + '
						WITH ENCRYPTION = OFF;'
				 , @paramDefinition	= '@handle UNIQUEIDENTIFIER OUTPUT'
		*/ 
	
		SET @i = @Cnt + 1
				
		WHILE @i <= @newCnt
		BEGIN
			BEGIN DIALOG CONVERSATION @handle
			FROM SERVICE  @fromService 
			TO SERVICE  @toService 
			on contract @contractName 
			WITH ENCRYPTION = OFF
			
			

		
			--EXECUTE sp_executesql @sql, @paramDefinition, @handle = @handle OUTPUT
			
			INSERT INTO sb.ConversationManagement(FunctionName, ConversationNo, ConversationHandle,CreatedDate,IsValid)
			VALUES(@functionName, @i, @handle,@CurrentDate,1)	
			
			SET @i = @i + 1					
		END
		
		UPDATE sb.ConversationCount WITH (ROWLOCK)
			SET Cnt = @newCnt
		WHERE FunctionName = @functionName
	END  
	ELSE
	BEGIN
		UPDATE sb.ConversationCount WITH (ROWLOCK)
			SET Cnt = @newCnt
		WHERE FunctionName = @functionName	  
	END
	
	SET NOCOUNT OFF
	
END
GO
