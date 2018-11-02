/*
	Create By: Johnson
	Created Date: 2018102
	Task: Apply Service Broker for Logging UserLog_Credit - [Redmine: #103547]
	DB: DBLOG/bodb_CustomerLog; 
	
*/	


--- send message to verify service broker set up
----------------- 1.1 Contract_CustomerLog_UserLog_Credit ----------------------
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_UserLog_Credit_DBLOG
TO SERVICE 'Service_UserLog_Credit_DBCUST'
ON CONTRACT Contract_CustomerLog_UserLog_Credit
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit (@Message)

GO

-- check message 
SELECT * FROM  dbo.Queue_UserLog_Credit

