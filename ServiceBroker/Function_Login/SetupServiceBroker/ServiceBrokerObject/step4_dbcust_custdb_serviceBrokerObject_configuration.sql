/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBCUST/CUSTDB 
	
*/	
------------ Setup Distributed --------------
/***************Step 1: configuration: Endpoint: creating port for target to connect, database, create window login of target machine (cross)*********/	
-- Enable service broker
USE [master]
GO
ALTER DATABASE bodb_CustomerLog SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE bodb_CustomerLog SET  ENABLE_BROKER WITH NO_WAIT
GO
ALTER DATABASE bodb_CustomerLog SET TRUSTWORTHY ON
GO
ALTER DATABASE bodb_CustomerLog SET MULTI_USER
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.endpoints
		   WHERE name = 'Endpoint_DBCust')
	DROP ENDPOINT Endpoint_DBCust
GO
CREATE ENDPOINT Endpoint_DBCust
STATE = STARTED
AS TCP
(
	LISTENER_PORT = 4740 --(Pick random)
)
FOR SERVICE_BROKER
(
	AUTHENTICATION = WINDOWS
)
GO
/*
IF EXISTS (SELECT TOP 1 1
		   FROM sys.server_principals
		   WHERE name = 'NT SERVICE\MSSQLSERVER'
		   AND [type] = 'G')
	DROP LOGIN [NT SERVICE\MSSQL$SQLSERVER2008R2]
GO
CREATE LOGIN [NT SERVICE\MSSQL$SQLSERVER2008R2] FROM WINDOWS
*/
GO
--GRANT CONNECT ON ENDPOINT::Endpoint_DBCust TO [NT SERVICE\MSSQLSERVER]
-- Local Test
GRANT CONNECT ON ENDPOINT::SSBSTargetEP TO [NT SERVICE\MSSQLSERVER]

GO

---ALTER DATABASE ServiceBroker_Initiator_OLTP SET TRUSTWORTHY ON: IF THE SAME INSTANCE
/***************END OF Step 1: configuration: Endpoint: creating port for target to connect, database, create window login of target machine (cross)*********/	

/***************Step 2: CREATE SERVICE BROKER COMPONENT: route (independant: alias of service want to connect): deploy distributed, message type, contract, queue, service *********/	
------------- SERVICE BROKER -----------
USE bodb_CustomerLog
GO
IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_queues
		   WHERE name = 'Queue_DBCUST')
	DROP QUEUE Queue_DBCUST
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.routes
		   WHERE name = 'Route_CustomerLog_DBCUST')
	DROP ROUTE Route_CustomerLog_DBCUST
GO

-----------------------
IF EXISTS (SELECT TOP 1 1
		   FROM sys.services
		   WHERE name = 'Service_CustomerLog_DBCUST')
	DROP SERVICE Service_CustomerLog_DBCUST
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_UserLog_Login')
	DROP MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
GO


IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_eaUserLog_Login')
	DROP MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_rmUserLog_Login')
	DROP MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login
GO

CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
GO

CREATE MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login

go
CREATE MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login
go
CREATE CONTRACT Contract_CustomerLog_UserLog_Login
(MessageType_CustomerLog_UserLog_Login SENT BY ANY)

CREATE CONTRACT Contract_CustomerLog_eaUserLog_Login
(MessageType_CustomerLog_eaUserLog_Login SENT BY ANY)


CREATE CONTRACT Contract_CustomerLog_rmUserLog_Login
( MessageType_CustomerLog_rmUserLog_Login SENT BY ANY)


GO

--------------------------------------
CREATE QUEUE Queue_DBCUST WITH RETENTION = OFF

CREATE SERVICE Service_CustomerLog_DBCUST
ON QUEUE Queue_DBCUST
(Contract_CustomerLog_UserLog_Login,Contract_CustomerLog_eaUserLog_Login,Contract_CustomerLog_rmUserLog_Login)

GO

CREATE ROUTE Route_CustomerLog_DBCUST -- point to destination
WITH SERVICE_NAME='Service_CustomerLog_DBLOG',
--local test
ADDRESS='TCP://DB215:4022' -- target server address
--local dev
--ADDRESS='TCP://DB231:4022' -- target server address
GO


/***************END OF Step 2: CREATE SERVICE BROKER COMPONENT: route (independant: alias of service want to connect): deploy distributed, message type, contract, queue, service *********/	

/***************Step 3: Setup logic to send message: create table, trigger,logic to send message  *********/	
-- Stored Procedures on the OLTP Database

/***************END OF Step 3: Setup logic to send message: create table, trigger,logic to send message  *********/	

/*
--TEST SERVICE

DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_CustomerLog_DBCUST
TO SERVICE 'Service_CustomerLog_DBLOG'
ON CONTRACT Contract_CustomerLog_UserLog_Login
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Login (@Message)

---
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_CustomerLog_DBCUST
TO SERVICE 'Service_CustomerLog_DBLOG'
ON CONTRACT Contract_CustomerLog_eaUserLog_Login
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login (@Message)

---
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_CustomerLog_DBCUST
TO SERVICE 'Service_CustomerLog_DBLOG'
ON CONTRACT Contract_CustomerLog_rmUserLog_Login
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login (@Message)


SELECT * FROM sys.transmission_queue
--Connection attempt failed with error: '10061(No connection could be made because the target machine actively refused it.)'.

--Connection attempt failed with error: '10061(No connection could be made because the target machine actively refused it.)'.
*/