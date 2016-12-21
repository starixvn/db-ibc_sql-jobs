/*
	Created By: Helen
	Created Date: 20161108
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBCUST/bodb_CustomerLog		
*/

-- [sb].[ConversationCount], [Sb].[ConversationManagement]	  
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_UserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @newCnt = 10
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_rmUserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @newCnt = 5
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_eaUserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @newCnt = 5	  	

  
----- CHECKING DATA ------------------
SELECT * FROM [sb].[ConfigurationReference] WITH (NOLOCK)	  

SELECT * FROM [sb].[ConfigurationReferenceDetail] WITH (NOLOCK)	 

SELECT * FROM [sb].[ConversationCount] WITH (NOLOCK)	 

SELECT * FROM [Sb].[ConversationManagement] WITH (NOLOCK)	 

SELECT s.name, e.far_service, e.is_initiator
			 , e.conversation_handle, e.conversation_id
			 , e.conversation_group_id, e.state, e.state_desc
			 , e.send_sequence
			 , e.system_sequence
FROM sys.conversation_endpoints e WITH(NOLOCK)
	INNER JOIN sys.services s WITH(NOLOCK) on e.service_id = s.service_id	  