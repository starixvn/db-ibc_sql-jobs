/*<info serverAlias="DBCUST-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBCUST/bodb_CustomerLog
*/
-- ConfigurationReferenceDetail
INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('UserLog_Others','Contract_CustomerLog_UserLog_RunSP','MessageType_CustomerLog_UserLog_RunSP',5,20)
GO
-- open 5 conversation
EXEC [sb].[DBA_ConversationManagement] @FunctionName = 'UserLog_Others'
	,	@ContractName = 'Contract_CustomerLog_UserLog_RunSP' 
	,	@FromService = 'Service_UserLog_Others_DBCUST'
	,	@ToService = 'Service_UserLog_Others_DBLOG'
	,	@Coversation_number = 5
	,	@Mode='AddNew'  

	