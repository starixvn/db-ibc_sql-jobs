/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBLOG/bodb_CustomerLog
	
*/	

/***************Step 1: configuration: Endpoint: creating port for target to connect, database, create window login of initiator machine (cross)*********/	
USE master
go
/*
IF EXISTS (SELECT TOP 1 1
		   FROM sys.endpoints
		   WHERE name = 'DBLOGEndpoint')
	DROP ENDPOINT DBLOGEndpoint
GO

CREATE ENDPOINT DBLOGEndpoint
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

IF EXISTS (SELECT TOP 1 1
		   FROM sys.server_principals
		   WHERE name = 'NT SERVICE\MSSQL$HELENSQLSERVER2'
		   AND [type] = 'G')
	DROP LOGIN [NT SERVICE\MSSQL$HELENSQLSERVER2]
GO
CREATE LOGIN [NT SERVICE\MSSQL$HELENSQLSERVER2] FROM WINDOWS
GO
*/
GRANT CONNECT ON ENDPOINT::SSBSTargetEP TO [NT SERVICE\MSSQLSERVER]
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
------------------------------------------------------------

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_contracts
		   WHERE name = 'Contract_CustomerLog')
	DROP CONTRACT Contract_CustomerLog
GO	
IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_UserLog_Login')
	DROP MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
GO

CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
GO

IF EXISTS (SELECT TOP 1 1
		   FROM sys.service_message_types
		   WHERE name = 'MessageType_CustomerLog_eaUserLog_Login')
	DROP MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login
	
CREATE MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login
GO
CREATE MESSAGE TYPE MessageType_CustomerLog_UserLog_Login
go
CREATE CONTRACT Contract_CustomerLog
(MessageType_CustomerLog_UserLog_Login SENT BY ANY
	
	)
GO
/*
drop contranct Contract_CustomerLog_tmp
create contract Contract_CustomerLog_tmp (MessageType_CustomerLog_eaUserLog_Login SENT BY ANY)
alter SERVICE Service_CustomerLog_DBLOG
(add contract Contract_CustomerLog_tmp)
*/

-----------------------------------------------------------------
GO
CREATE QUEUE Queue_DBLOG WITH RETENTION = OFF ON servicebroker
GO

CREATE SERVICE Service_CustomerLog_DBLOG
ON QUEUE Queue_DBLOG
(Contract_CustomerLog)

create ROUTE Route_CustomerLog_DBLOG -- point back to sourcxe
WITH SERVICE_NAME='Service_CustomerLog_DBCUST',
ADDRESS='TCP://DB230:4740' -- Source address	
GO
GRANT SEND ON SERVICE::[Service_CustomerLog_DBLOG] TO PUBLIC -- Grant send permission, only need to run against target side
GO
/***************END OF Step 2: CREATE SERVICE BROKER COMPONENT: route (independant: alias of service want to connect): deploy distributed, message type, contract, queue, service *********/	

/***************Step 3: Setup logic to receive message: create table,sp(s), logic to receive message  *********/	
--- Procedures on the Reporting Database

USE bodb_CustomerLog
GO
ALTER QUEUE [Queue_DBLOG]
WITH
	STATUS = ON,
	
	ACTIVATION(
				STATUS = ON,
				PROCEDURE_NAME = [sb].CustomerLog_ProcessData,
				MAX_QUEUE_READERS = 10, -- Maximum Number of queue reader can be started at the same time
				EXECUTE AS 'dbo'
			);	
/***************END OF Step 3: Setup logic to receive message: create table,sp(s), logic to receive message  *********/					
/*
RECEIVE TOP(5) CONVERT(NVARCHAR(MAX), message_body) AS Message
FROM Queue_DBLOG

select * FROM Queue_DBLOG
select * from 

RECEIVE TOP(5) CONVERT(NVARCHAR(MAX), message_body) AS Message
FROM Queue_DBLOG

*/

