USE [bodb_CustomerLog]
GO

DELETE sb.ConfigurationReferenceDetail
WHERE ContractName = 'Contract_CustomerLog_CS_UserLog_Login';

INSERT INTO sb.ConfigurationReferenceDetail(FunctionName, ContractName, MessageType, MinConversation, MaxConversation)
VALUES	('Login', 'Contract_CustomerLog_CS_UserLog_Login', 'MessageType_CustomerLog_CS_UserLog_Login', 5, 20);