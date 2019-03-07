/*
	Create By: Johnson
	Created Date: 2018102
	Task: Apply Service Broker for Logging UserLog_Credit - [Redmine: #103547]
	DB: DBLOG/bodb_CustomerLog; 
	
*/	
-- check message from DBCUST
SELECT * FROM  dbo.Queue_Others

--- send message to verify service broker set up
----------------- 1.1 Contract_CustomerLog_UserLog_Credit ----------------------
--Check Route to DBCUST
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_UserLog_Others_DBLOG
TO SERVICE 'Service_UserLog_Others_DBCUST'
ON CONTRACT Contract_CustomerLog_UserLog_Credit
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message From DBLOG to DBCUST';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit (@Message)

GO

--Check Route to DBLOGBK
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_UserLog_Others_DBLOG
TO SERVICE 'Service_UserLog_Others_DBLOGBK'
ON CONTRACT Contract_CustomerLog_UserLog_Credit_BK
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message  From DBLOG to DBLOGBK';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit_BK (@Message)

GO

--check pending messages on DBLOG
SELECT transmission_status,* FROM sys.transmission_queue