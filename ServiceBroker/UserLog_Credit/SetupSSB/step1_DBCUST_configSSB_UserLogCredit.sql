/*
	Created: Johnson
	Date: 2018-10-22
	Task: setup service broker objects for UserLog_Credit on DBCUST
	DB: DBCUST/bodb_CustomerLog
*/
USE [bodb_CustomerLog]
GO
IF EXISTS(SELECT TOP 1 1 FROM sys.services
		WHERE name = 'Service_UserLog_Credit_DBCUST'
		)
DROP SERVICE Service_UserLog_Credit_DBCUST
GO
	
IF EXISTS(SELECT TOP 1 1 FROM sys.service_contracts 
		WHERE name = 'Contract_CustomerLog_UserLog_Credit')
DROP CONTRACT Contract_CustomerLog_UserLog_Credit
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.service_queues
		   WHERE name = 'Queue_UserLog_Credit')
DROP QUEUE Queue_UserLog_Credit
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.routes
		WHERE name = 'Route_UserLog_Credit_DBCUST')
DROP ROUTE Route_UserLog_Credit_DBCUST
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

CREATE QUEUE [dbo].[Queue_UserLog_Credit] WITH STATUS = ON , RETENTION = OFF , 
POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBrokerData] 
GO

CREATE SERVICE [Service_UserLog_Credit_DBCUST] AUTHORIZATION [dbo] ON QUEUE dbo.[Queue_UserLog_Credit](Contract_CustomerLog_UserLog_Credit)
GO

CREATE ROUTE [Route_UserLog_Credit_DBCUST] AUTHORIZATION dbo
WITH  SERVICE_NAME  = N'Service_UserLog_Credit_DBLOG' ,  
-- Production
ADDRESS='TCP://DBLOG:4741' -- target server address
--local test
--ADDRESS='TCP://DB215:4741' -- target server address
--local dev
--ADDRESS='TCP://DB231:4741' -- target server address
GO 

--Grant send/receive for accounts
GRANT SEND ON SERVICE::Service_UserLog_Credit_DBCUST TO [bodbExtAccNet]
GRANT SEND ON SERVICE::Service_UserLog_Credit_DBCUST  TO bodbDownlineNet
GRANT SEND ON SERVICE::Service_UserLog_Credit_DBCUST  TO [bodbDownlineNetView]
GRANT SEND ON SERVICE::Service_UserLog_Credit_DBCUST  TO [vnteam]

GRANT RECEIVE ON Queue_UserLog_Credit TO [bodbExtAccNet]
GRANT RECEIVE ON Queue_UserLog_Credit TO bodbDownlineNet
GRANT RECEIVE ON Queue_UserLog_Credit TO [bodbDownlineNetView]
GRANT RECEIVE ON Queue_UserLog_Credit TO [vnteam]

