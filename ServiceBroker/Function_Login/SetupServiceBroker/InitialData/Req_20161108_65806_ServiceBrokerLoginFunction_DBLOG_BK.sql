/*
	Created By: Kent
	Created Date: 20161108
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBLOG_BK/bodb_CustomerLog		
*/
--[sb].[ConfigurationReference]
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'Login'
GO
INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('Login',1,200)
GO
--[sb].[ConfigurationReferenceDetail]
GO
