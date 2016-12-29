/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBCUST/bodb_CustomerLog; 
	
*/	


--- send message to verify service broker set up
----------------- 1.1 Contract_CustomerLog_UserLog_Login ----------------------
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

GO
-------------- 1.2 Contract_CustomerLog_eaUserLog_Login ----------------------
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

GO
-- ------------------1.3 Contract_CustomerLog_rmUserLog_Login ------------------------
--DECLARE @SBDialog uniqueidentifier
--DECLARE @Message NVARCHAR(128)

--BEGIN DIALOG CONVERSATION @SBDialog
--FROM SERVICE Service_CustomerLog_DBCUST
--TO SERVICE 'Service_CustomerLog_DBLOG'
--ON CONTRACT Contract_CustomerLog_rmUserLog_Login
--WITH ENCRYPTION = OFF

---- Send messages on Dialog
--SET @Message = N'Very First Message';
--SEND ON CONVERSATION @SBDialog
--MESSAGE TYPE MessageType_CustomerLog_rmUserLog_Login (@Message)

--GO

-- PLEASE CALM DOWN IF MESSAGES EXISTS IN transmission_queue, WAITING FOR 5S AND TRY AGAIN
SELECT transmission_status,* FROM sys.transmission_queue