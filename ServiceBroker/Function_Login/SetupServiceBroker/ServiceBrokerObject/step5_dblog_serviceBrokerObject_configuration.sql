/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBLOG/bodb_CustomerLog; 
	
*/	
--------------- PLEASE RUN STEPS BY STEPS -----------------------------
/***************Step 1: configuration: Endpoint: creating port for target to connect, database, create window login of initiator machine (cross)*********/	

	-- Enable service broker
	USE [master]
	GO
	ALTER DATABASE [bodb_CustomerLog] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	GO
	ALTER DATABASE [bodb_CustomerLog] SET  ENABLE_BROKER WITH NO_WAIT
	GO
	--ALTER DATABASE [bodb_CustomerLog] SET TRUSTWORTHY ON
	GO
	ALTER DATABASE [bodb_CustomerLog] SET MULTI_USER
	GO
	------------------------------------------------
	USE master
	go

	IF EXISTS (SELECT TOP 1 1
			   FROM sys.endpoints
			   WHERE name = 'DBLOGEndpoint')
		DROP ENDPOINT Endpoint_DBLOG
	GO

	CREATE ENDPOINT Endpoint_DBLOG
	STATE = STARTED
	AS TCP
	(
		LISTENER_PORT = 4741
	)
	FOR SERVICE_BROKER
	(
		AUTHENTICATION = WINDOWS
	)
	GO
	--Create window login of target machine (cross), please double check first before running command below, IF it exists we will use it
	/*
	IF EXISTS (SELECT TOP 1 1
			   FROM sys.server_principals
			   WHERE name = 'NT SERVICE\MSSQLSERVER'
			   AND [type] = 'G')
		DROP LOGIN [NT SERVICE\MSSQLSERVER]
	GO
	CREATE LOGIN [NT SERVICE\MSSQLSERVER] FROM WINDOWS
	*/
	--GO

	GRANT CONNECT ON ENDPOINT::Endpoint_DBLOG TO [NT SERVICE\MSSQLSERVER] -- window account of dbcust
	GO
	GRANT CONNECT ON ENDPOINT::Endpoint_DBLOG TO [NT SERVICE\MSSQLSERVER] --window account of dblog_bk

	-- Local test
	/*
	GRANT CONNECT ON ENDPOINT::SSBSTargetEP TO [NT SERVICE\MSSQLSERVER] -- window account of dbcust
	GRANT CONNECT ON ENDPOINT::SSBSTargetEP TO [NT SERVICE\MSSQLSERVER] --window account of dblog_bk
	*/
	GO

/***************END OF Step 1: configuration: Endpoint: creating port for souce to target, database, create window login of initiator machine (cross)*********/	

/***************Step 2: CREATE SERVICE BROKER COMPONENT: route (independant: alias of service want to connect): deploy distributed, message type, contract, queue, service *********/	 
------------- SERVICE BROKER -----------
USE bodb_CustomerLog
GO
IF EXISTS (SELECT TOP 1 1
		   FROM sys.services
		   WHERE name = 'Service_CustomerLog_DBLOG')
	DROP SERVICE Service_CustomerLog_DBLOG
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_queues
		   WHERE name = 'Queue_DBLOG')
	DROP QUEUE Queue_DBLOG
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.routes
		   WHERE name = 'Route_CustomerLog_DBLOG')
	DROP ROUTE Route_CustomerLog_DBLOG
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.routes
		   WHERE name = 'Route_CustomerLog_DBLOG_BK')
	DROP ROUTE Route_CustomerLog_DBLOG_BK
GO


------------------------------------------------------------

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_contracts
		   WHERE name = 'Contract_CustomerLog_UserLog_Login')
	DROP CONTRACT Contract_CustomerLog_UserLog_Login
GO
IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_contracts
		   WHERE name = 'Contract_CustomerLog_eaUserLog_Login')
	DROP CONTRACT Contract_CustomerLog_eaUserLog_Login
GO
IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_contracts
		   WHERE name = 'Contract_CustomerLog_rmUserLog_Login')
	DROP CONTRACT Contract_CustomerLog_rmUserLog_Login
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
go

CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
GO
CREATE MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login
go
CREATE MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login
GO

go
CREATE CONTRACT Contract_CustomerLog_UserLog_Login
(MessageType_CustomerLog_UserLog_Login SENT BY ANY)
GO
CREATE CONTRACT Contract_CustomerLog_eaUserLog_Login
(MessageType_CustomerLog_eaUserLog_Login SENT BY ANY)
GO
CREATE CONTRACT Contract_CustomerLog_rmUserLog_Login
(MessageType_CustomerLog_rmUserLog_Login SENT BY ANY)
GO
-----------------------------------------------------------------
GO
CREATE QUEUE Queue_DBLOG WITH RETENTION = OFF ON servicebroker
GO

CREATE SERVICE Service_CustomerLog_DBLOG
ON QUEUE Queue_DBLOG
(Contract_CustomerLog_UserLog_Login,Contract_CustomerLog_eaUserLog_Login,Contract_CustomerLog_rmUserLog_Login)

CREATE ROUTE Route_CustomerLog_DBLOG -- point back to sourcxe
WITH SERVICE_NAME='Service_CustomerLog_DBCUST',
-- Production
ADDRESS='TCP://DBCUST:4022' -- Source address	
--local test
--ADDRESS='TCP://DB233:4022' -- Source address	
-- local dev
--ADDRESS='TCP://DB230:4740' -- Source address	
GO

CREATE ROUTE Route_CustomerLog_DBLOG_BK -- point  to dblog_bk
WITH SERVICE_NAME='Service_CustomerLog_DBLOG_BK',
-- Production
ADDRESS='TCP://DBLOG_BK:4022' -- target address	
-- local test
--ADDRESS='TCP://DB234:4022' -- target address	
-- local dev
--ADDRESS='TCP://DB231:4742' -- target address	
GO

go
GRANT SEND ON SERVICE::[Service_CustomerLog_DBLOG] TO PUBLIC -- Grant send permission, only need to run against target side
GO

GRANT SEND ON SERVICE::Service_CustomerLog_DBLOG TO [bodbExtAccNet]
GRANT SEND ON SERVICE::Service_CustomerLog_DBLOG  TO bodbDownlineNet
GRANT SEND ON SERVICE::Service_CustomerLog_DBLOG  TO [bodbRMSNet]
GRANT SEND ON SERVICE::Service_CustomerLog_DBLOG  TO [bodbDownlineNetView]
GRANT SEND ON SERVICE::Service_CustomerLog_DBLOG  TO [vnteam]
GO
GRANT RECEIVE ON Queue_DBLOG TO [bodbExtAccNet]
GRANT RECEIVE ON Queue_DBLOG TO bodbDownlineNet
GRANT RECEIVE ON Queue_DBLOG TO [bodbRMSNet]
GRANT RECEIVE ON Queue_DBLOG TO [bodbDownlineNetView]
GRANT RECEIVE ON Queue_DBLOG TO [vnteam]

/***************END OF Step 2: CREATE SERVICE BROKER COMPONENT: route (independant: alias of service want to connect): deploy distributed, message type, contract, queue, service *********/	

/***************Step 3: Setup logic to receive message: create table,sp(s), logic to receive message  *********/	
--- Procedures on the Reporting Database

USE bodb_CustomerLog
GO
ALTER QUEUE [Queue_DBLOG]
WITH
	STATUS = ON,
	
	ACTIVATION(
				STATUS = OFF,
				PROCEDURE_NAME = [sb].CustomerLog_ProcessData,
				MAX_QUEUE_READERS = 10, -- Maximum Number of queue reader can be started at the same time
				EXECUTE AS 'dbo'
			);	
			
/***************END OF Step 3: Setup logic to receive message: create table,sp(s), logic to receive message  *********/					

