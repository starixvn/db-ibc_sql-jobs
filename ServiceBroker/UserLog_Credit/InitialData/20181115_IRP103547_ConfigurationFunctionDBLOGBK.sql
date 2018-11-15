/*
	Created By: Johnson
	Created Date: 20181115
	Task: Initial data for service UserLog_Credit on DBLOGBK
	DB: DBLOGBK/bodb_CustomerLog	
*/
USE bodb_CustomerLog
GO
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConfigurationReferenceDetail] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConversationCount] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConversationManagement] WHERE [FunctionName] = 'UserLog_Others'
GO


INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('UserLog_Others',100,200)
GO
--[sb].[ConfigurationReferenceDetail]

INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('UserLog_Others','Contract_CustomerLog_UserLog_Credit','MessageType_CustomerLog_UserLog_Credit',5,20)
	
GO