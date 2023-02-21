/*<info serverAlias="DBTXN-bodb_CustomerLog"></info>*/
USE bodb_CustomerLog
GO

CREATE MESSAGE TYPE [MessageType_UserLog] VALIDATION = NONE
GO
CREATE CONTRACT [Contract_UserLog] ([MessageType_UserLog] SENT BY ANY)
GO
CREATE QUEUE [dbo].[Queue_UserLog] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBroker] 
GO
--dbtrans
CREATE SERVICE [Service_UserLog_DBTXN]  ON QUEUE [dbo].[Queue_UserLog] ([Contract_UserLog])
GO
--site1
CREATE SERVICE [Service_UserLog_DBGRP01L]  ON QUEUE [dbo].[Queue_UserLog] ([Contract_UserLog])
GO
--site2
CREATE SERVICE [Service_UserLog_DBGRP02L]  ON QUEUE [dbo].[Queue_UserLog] ([Contract_UserLog])
GO
--need to update ADDRESS info on each environment
CREATE ROUTE [Route_UserLog_DBLOG]   WITH  SERVICE_NAME  = N'Service_UserLog_DBLOG',  ADDRESS  = N'TCP://10.18.200.61:4742' 
GO

GRANT SEND ON SERVICE::[Service_UserLog_DBTXN] TO [public] AS [dbo]
GO
