/*
	Create By: Johnson
	Created Date: 2018102
	Task: Apply Service Broker for Logging UserLog_Credit - [Redmine: #103547]
	DB: DBCUST/bodb_CustomerLog; 
	
*/	


--- send message to verify service broker set up
----------------- 1.1 Contract_CustomerLog_UserLog_Credit ----------------------
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_UserLog_Credit_DBCUST
TO SERVICE 'Service_UserLog_Credit_DBLOG'
ON CONTRACT Contract_CustomerLog_UserLog_Credit
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit (@Message)

GO

-- PLEASE CALM DOWN IF MESSAGES EXISTS IN transmission_queue, WAITING FOR 5S AND TRY AGAIN
SELECT transmission_status,* FROM sys.transmission_queue