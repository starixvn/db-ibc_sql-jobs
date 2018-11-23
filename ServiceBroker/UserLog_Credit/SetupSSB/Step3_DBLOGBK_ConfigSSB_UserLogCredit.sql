/*
	Created: Johnson
	Date: 2018-11-14
	Task: setup service broker objects for UserLog_Others on DBLOGBK
	DB: DBLOGBK/bodb_CustomerLog
*/
USE [bodb_CustomerLog]
GO
IF EXISTS(SELECT TOP 1 1 FROM sys.services
		WHERE name = 'Service_UserLog_Others_DBLOGBK'
		)
DROP SERVICE Service_UserLog_Others_DBLOGBK
GO
	
IF EXISTS(SELECT TOP 1 1 FROM sys.service_contracts 
		WHERE name = 'Contract_CustomerLog_UserLog_Credit')
DROP CONTRACT Contract_CustomerLog_UserLog_Credit
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.service_queues
		   WHERE name = 'Queue_Others')
DROP QUEUE Queue_Others
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.routes
		WHERE name = 'Route_UserLog_Others_To_DBLOG')
DROP ROUTE Route_UserLog_Others_To_DBLOG
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_UserLog_Credit')
DROP MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit
GO

--Create messagetype,contract,service for SSB UserLog_Credit 
CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit AUTHORIZATION [dbo] 
GO

CREATE CONTRACT [Contract_CustomerLog_UserLog_Credit] AUTHORIZATION [dbo]
([MessageType_CustomerLog_UserLog_Credit] SENT BY ANY)
GO

CREATE QUEUE [dbo].[Queue_Others] WITH STATUS = ON , RETENTION = OFF , 
POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBrokerData] 
GO

ALTER QUEUE Queue_Others 
WITH ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [sb].[QueueOthersDBLOGBK_ProcessData] , MAX_QUEUE_READERS = 10 , EXECUTE AS N'dbo'  )
GO

CREATE SERVICE [Service_UserLog_Others_DBLOGBK] AUTHORIZATION [dbo] ON QUEUE dbo.[Queue_Others](Contract_CustomerLog_UserLog_Credit)
GO

CREATE ROUTE [Route_UserLog_Others_To_DBLOG] AUTHORIZATION dbo
WITH  SERVICE_NAME  = N'Service_UserLog_Others_DBLOG' ,  
-- Production
ADDRESS='TCP://DB052:4741' -- target server address
--local test
--ADDRESS='TCP://DB215:4741' -- target server address
--local dev
--ADDRESS='TCP://DB231:4741' -- target server address
GO 

--Grant send/receive for accounts
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOGBK TO [bodbExtAccNet]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOGBK  TO bodbDownlineNet
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOGBK  TO [bodbDownlineNetView]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOGBK  TO [vnteam]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOGBK  TO public

GRANT RECEIVE ON Queue_Others TO [bodbExtAccNet]
GRANT RECEIVE ON Queue_Others TO bodbDownlineNet
GRANT RECEIVE ON Queue_Others TO [bodbDownlineNetView]
GRANT RECEIVE ON Queue_Others TO [vnteam]
GRANT RECEIVE ON Queue_Others TO public

