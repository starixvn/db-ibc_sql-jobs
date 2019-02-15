/*
	Created: Johnson
	Date: 2018-10-23
	Task: setup service broker objects for UserLog_Credit on DBLOG
	DB: DBLOG/bodb_CustomerLog
*/
USE [bodb_CustomerLog]
GO
IF EXISTS(SELECT TOP 1 1 FROM sys.services
		WHERE name = 'Service_UserLog_Others_DBLOG'
		)
DROP SERVICE Service_UserLog_Others_DBLOG
GO
	
IF EXISTS(SELECT TOP 1 1 FROM sys.service_contracts 
		WHERE name = 'Contract_CustomerLog_UserLog_Credit')
DROP CONTRACT Contract_CustomerLog_UserLog_Credit
GO

IF EXISTS(SELECT TOP 1 1 FROM sys.service_contracts 
		WHERE name = 'Contract_CustomerLog_UserLog_Credit_BK')
DROP CONTRACT Contract_CustomerLog_UserLog_Credit_BK
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.service_queues
		   WHERE name = 'Queue_Others')
DROP QUEUE Queue_Others
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.routes
		WHERE name = 'Route_UserLog_Others_To_DBCUST')
DROP ROUTE Route_UserLog_Others_To_DBCUST
GO

IF EXISTS (SELECT TOP 1 1 FROM sys.routes
		WHERE name = 'Route_UserLog_Others_To_DBLOGBK')
DROP ROUTE Route_UserLog_Others_To_DBLOGBK
GO

IF EXISTS(SELECT TOP 1 1 FROM sys.service_message_types 
		WHERE name = 'MessageType_CustomerLog_UserLog_Credit')
DROP MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit
GO

IF EXISTS(SELECT TOP 1 1 FROM sys.service_message_types 
		WHERE name = 'MessageType_CustomerLog_UserLog_Credit_BK')
DROP MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit_BK
GO

--Create messagetype,contract,service for SSB UserLog_Credit 
CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit AUTHORIZATION [dbo]
GO

CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit_BK AUTHORIZATION [dbo]
GO

CREATE CONTRACT [Contract_CustomerLog_UserLog_Credit] AUTHORIZATION [dbo]
([MessageType_CustomerLog_UserLog_Credit] SENT BY ANY)
GO

CREATE CONTRACT [Contract_CustomerLog_UserLog_Credit_BK] AUTHORIZATION [dbo]
([MessageType_CustomerLog_UserLog_Credit_BK] SENT BY ANY)
GO

CREATE QUEUE [dbo].[Queue_Others] WITH STATUS = ON , RETENTION = OFF ,
POISON_MESSAGE_HANDLING (STATUS = ON)  ON [ServiceBrokerData] 
GO

CREATE SERVICE [Service_UserLog_Others_DBLOG] AUTHORIZATION [dbo] 
ON QUEUE dbo.[Queue_Others](Contract_CustomerLog_UserLog_Credit,
							Contract_CustomerLog_UserLog_Credit_BK)
GO

--create route to DBCUST

CREATE ROUTE [Route_UserLog_Others_To_DBCUST] AUTHORIZATION dbo
WITH  SERVICE_NAME  = N'Service_UserLog_Others_DBCUST' , 
--Production  
ADDRESS='TCP://DBCUST:4740' -- target server address
--Local Test
--ADDRESS='TCP://DB233:4740' -- target server address
--Local Dev
--ADDRESS='TCP://DB230:4740' -- target server address
GO 

--create Route to DBLOG_BK
CREATE ROUTE [Route_UserLog_Others_To_DBLOGBK] AUTHORIZATION dbo
WITH  SERVICE_NAME  = N'Service_UserLog_Others_DBLOGBK' , 
--Production  
ADDRESS='TCP://DB054:4742' -- target server address
--Local Test
--ADDRESS='TCP://DB234:4742' -- target server address
--Local Dev
--ADDRESS='TCP://DB231:4742' -- target server address
GO 

--Grant send/receive for accounts
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOG TO [bodbExtAccNet]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOG  TO bodbDownlineNet
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOG  TO [bodbDownlineNetView]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOG  TO [vnteam]
GRANT SEND ON SERVICE::Service_UserLog_Others_DBLOG  TO public

GRANT RECEIVE ON Queue_Others TO [bodbExtAccNet]
GRANT RECEIVE ON Queue_Others TO bodbDownlineNet
GRANT RECEIVE ON Queue_Others TO [bodbDownlineNetView]
GRANT RECEIVE ON Queue_Others TO [vnteam]
GRANT RECEIVE ON Queue_Others TO public
