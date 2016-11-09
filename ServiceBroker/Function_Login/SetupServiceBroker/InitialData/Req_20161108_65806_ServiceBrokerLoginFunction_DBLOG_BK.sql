/*
	Created By: Kent
	Created Date: 20161108
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBLOG_BK/bodb_CustomerLog		
*/
--[sb].[ConfigurationReference]
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'Login'
GO
DELETE FROM [sb].[ConfigurationReferenceDetail] WHERE [FunctionName] = 'Login'
go
INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('Login',100,200)
GO
--[sb].[ConfigurationReferenceDetail]
GO
INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('Login','Contract_CustomerLog_UserLog_Login','MessageType_CustomerLog_UserLog_Login',5,20)
	  ,('Login','Contract_CustomerLog_rmUserLog_Login','MessageType_CustomerLog_rmUserLog_Login',5,20)
	  ,('Login','Contract_CustomerLog_eaUserLog_Login','MessageType_CustomerLog_eaUserLog_Login',5,20)