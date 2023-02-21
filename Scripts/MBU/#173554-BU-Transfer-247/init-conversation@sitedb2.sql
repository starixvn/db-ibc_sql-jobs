/*<info serverAlias="DBTXN-bodb_CustomerLog"></info>*/
USE bodb_CustomerLog
GO
select * from sb.ConfigurationReference

select * from sb.ConfigurationReferenceDetail

select * from sb.ConversationCount

select * from sb.ConversationManagement

insert into sb.ConfigurationReference(FunctionName, MaxReceiveMsg, MaxReceiveTimeOut)
values('UserLog', 100, 100)

insert into sb.ConfigurationReferenceDetail(FunctionName, ContractName, MessageType, MinConversation, MaxConversation)
values('UserLog', 'Contract_UserLog', 'MessageType_UserLog', 0, 5)

--site2
EXEC sb.DBA_ConversationManagement 
	  @functionName = 'UserLog'
	, @contractName = 'Contract_UserLog'		  
	, @fromService = 'Service_UserLog_DBGRP02L'
	, @toService = 'Service_UserLog_DBLOG'
	, @Coversation_number = 5
	, @Mode = 'Reset'

GO
