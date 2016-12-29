/*
	Created By: Kent
	Created Date: 20161108
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBLOG/bodb_CustomerLog		
*/
-- [sb].[ConversationCount], [Sb].[ConversationManagement]	  
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_UserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBLOG'
	  , @toService = 'Service_CustomerLog_DBLOG_BK'
	  , @newCnt = 10
	  
GO
--EXEC [Sb].[ConversationManagement_Upd] 
--		@functionName = 'Login'
--	  , @contractName = 'Contract_CustomerLog_rmUserLog_Login'		  
--	  , @fromService = 'Service_CustomerLog_DBLOG'
--	  , @toService = 'Service_CustomerLog_DBLOG_BK'
--	  , @newCnt = 5
--GO
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_eaUserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBLOG'
	  , @toService = 'Service_CustomerLog_DBLOG_BK'
	  , @newCnt = 5	  
GO	  

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
	  
 	  	  		  
