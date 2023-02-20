/*<info serverAlias="DBTXN-bodb_CustomerLog"></info>*/
USE bodb_CustomerLog
GO

EXEC sb.DBA_ConversationManagement 
	  @functionName = 'UserLog'
	, @contractName = 'Contract_UserLog'		  
	, @fromService = 'Service_UserLog_DBTXN'
	, @toService = 'Service_UserLog_DBLOG'
	, @Coversation_number = 5
	, @Mode = 'Reset'

GO