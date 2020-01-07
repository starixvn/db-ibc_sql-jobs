USE [bodb_CustomerLog]
GO

EXEC [sb].[ConversationManagement_Upd] 
		@functionName = 'UserLog_Others'
	  , @contractName = 'Contract_CustomerLog_CS_UserLog_Credit'		  
	  , @fromService = 'Service_UserLog_Others_DBCUST'
	  , @toService = 'Service_UserLog_Others_DBLOG'
	  , @newCnt = 10	