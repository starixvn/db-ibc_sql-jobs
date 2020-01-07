USE [bodb_CustomerLog]
GO

IF NOT EXISTS (	
				SELECT 1
				FROM sys.service_message_types
				WHERE name = 'MessageType_CustomerLog_CS_UserLog_Credit'
				)
BEGIN
	CREATE MESSAGE TYPE [MessageType_CustomerLog_CS_UserLog_Credit] VALIDATION = NONE
END
GO

IF NOT EXISTS (	
				SELECT 1
				FROM sys.service_contracts
				WHERE name = 'Contract_CustomerLog_CS_UserLog_Credit'
				)
BEGIN
	CREATE CONTRACT [Contract_CustomerLog_CS_UserLog_Credit] ([MessageType_CustomerLog_CS_UserLog_Credit] SENT BY ANY)
END
GO

IF NOT EXISTS (	
				SELECT 1
				FROM sys.services s
					INNER JOIN sys.service_contract_usages scu ON s.service_id = scu.service_id
					INNER JOIN sys.service_contracts sc ON sc.service_contract_id = scu.service_contract_id
				WHERE s.name = 'Service_UserLog_Others_DBCUST'
					AND sc.name = 'Contract_CustomerLog_CS_UserLog_Credit'
				)
BEGIN
	ALTER SERVICE [Service_UserLog_Others_DBCUST]  (ADD CONTRACT [Contract_CustomerLog_CS_UserLog_Credit])
END
GO