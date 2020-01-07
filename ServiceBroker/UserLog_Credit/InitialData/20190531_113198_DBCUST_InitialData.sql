USE [bodb_CustomerLog]
GO

DELETE sb.ConfigurationReferenceDetail
WHERE ContractName = 'Contract_CustomerLog_CS_UserLog_Credit';

INSERT INTO sb.ConfigurationReferenceDetail(FunctionName, ContractName, MessageType, MinConversation, MaxConversation)
VALUES	('UserLog_Others', 'Contract_CustomerLog_CS_UserLog_Credit', 'MessageType_CustomerLog_CS_UserLog_Credit', 5, 20);