/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBLOG/bodb_CustomerLog; 
	
*/	

-- Step 1:
SELECT CONVERT(NVARCHAR(MAX), message_body) AS Message  FROM QUEUE_DBLOG 
-- if exist messsage from this queue, we will continue to receive message and send to dblog bk
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_CustomerLog_DBLOG
TO SERVICE 'Service_CustomerLog_DBLOG_BK'
ON CONTRACT Contract_CustomerLog_UserLog_Login
WITH ENCRYPTION = OFF;

-- Send messages on Dialog
RECEIVE TOP (1) @Message = message_body 
FROM QUEUE_DBLOG;

SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Login (@Message)

GO
-- if exist messsage from this queue, we will continue to receive message and send to dblog bk
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_CustomerLog_DBLOG
TO SERVICE 'Service_CustomerLog_DBLOG_BK'
ON CONTRACT Contract_CustomerLog_eaUserLog_Login
WITH ENCRYPTION = OFF;

-- Send messages on Dialog
RECEIVE TOP (1) @Message = message_body 
FROM QUEUE_DBLOG;

SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_eaUserLog_Login (@Message)

GO
-- if exist messsage from this queue, we will continue to receive message and send to dblog bk
--DECLARE @SBDialog uniqueidentifier
--DECLARE @Message NVARCHAR(128)

--BEGIN DIALOG CONVERSATION @SBDialog
--FROM SERVICE Service_CustomerLog_DBLOG
--TO SERVICE 'Service_CustomerLog_DBLOG_BK'
--ON CONTRACT Contract_CustomerLog_rmUserLog_Login
--WITH ENCRYPTION = OFF;

---- Send messages on Dialog
--RECEIVE TOP (1) @Message = message_body 
--FROM QUEUE_DBLOG;

--SEND ON CONVERSATION @SBDialog
--MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login (@Message)

--GO


-- Select 
SELECT * FROM QUEUE_DBLOG 
SELECT * FROM sys.transmission_queue


