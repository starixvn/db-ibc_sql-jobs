USE [bodb_CustomerLog]
GO

EXEC [sb].[ConversationManagement_Upd] 
		@functionName = 'Login'
	  , @contractName = 'Contract_CustomerLog_CS_UserLog_Login'		  
	  , @fromService = 'Service_CustomerLog_DBCUST'
	  , @toService = 'Service_CustomerLog_DBLOG'
	  , @newCnt = 10