/*
	Created By: Johnson
	Created Date: 20181031
	Task: Initial conversations for service UserLog_Credit
	DB: DBCUST/bodb_CustomerLog	
*/
USE bodb_CustomerLog
GO
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'UserLog_Credit'
GO
DELETE FROM [sb].[ConfigurationReferenceDetail] WHERE [FunctionName] = 'UserLog_Credit'
GO
DELETE FROM [sb].[ConversationCount] WHERE [FunctionName] = 'UserLog_Credit'
GO
DELETE FROM [sb].[ConversationManagement] WHERE [FunctionName] = 'UserLog_Credit'
GO
INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('UserLog_Credit',100,200)
GO
--[sb].[ConfigurationReferenceDetail]

INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('UserLog_Credit','Contract_CustomerLog_UserLog_Credit','MessageType_CustomerLog_UserLog_Credit',5,20)
	
GO



