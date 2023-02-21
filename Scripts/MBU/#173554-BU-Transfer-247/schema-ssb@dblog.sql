/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
USE bodb_CustomerLog
GO

CREATE MESSAGE TYPE [MessageType_UserLog] VALIDATION = NONE
GO
CREATE CONTRACT [Contract_UserLog] ([MessageType_UserLog] SENT BY ANY)
GO
CREATE QUEUE [dbo].[Queue_UserLog] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBroker] 
GO
CREATE SERVICE [Service_UserLog_DBLOG]  ON QUEUE [dbo].[Queue_UserLog] ([Contract_UserLog])
GO
--need to update ADDRESS info on each environment
CREATE ROUTE [Route_UserLog_DBTXN]   WITH  SERVICE_NAME  = N'Service_UserLog_DBTXN',  ADDRESS  = N'TCP://DB231:4741' 
GO
CREATE ROUTE [Route_UserLog_DBGRP01L]   WITH  SERVICE_NAME  = N'Service_UserLog_DBTXN',  ADDRESS  = N'TCP://DB231:4741' 
GO
CREATE ROUTE [Route_UserLog_DBGRP02L]   WITH  SERVICE_NAME  = N'Service_UserLog_DBTXN',  ADDRESS  = N'TCP://DB231:4741' 
GO

GRANT SEND ON SERVICE::[Service_UserLog_DBTXN] TO [public] AS [dbo]
GO

USE [bodb_CustomerLog]
GO
ALTER QUEUE [dbo].[Queue_UserLog] WITH STATUS = ON, ACTIVATION (  STATUS = ON , PROCEDURE_NAME = dbo.UserLog_Process_Message , MAX_QUEUE_READERS = 2 , EXECUTE AS N'dbo'  ) , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = ON) 