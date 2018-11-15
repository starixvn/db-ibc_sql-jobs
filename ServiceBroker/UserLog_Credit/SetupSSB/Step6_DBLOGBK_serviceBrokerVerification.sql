/*
	Create By: Johnson
	Created Date: 20181114
	Task: Apply Service Broker for Logging UserLog_Credit - [Redmine: #103547]
	DB: DBLOGBK/bodb_CustomerLog; 
	
*/	
-- check message from DBLOG
SELECT * FROM  dbo.Queue_Others
GO

--Check Route to DBLOGBK
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

BEGIN DIALOG CONVERSATION @SBDialog
FROM SERVICE Service_UserLog_Others_DBLOGBK
TO SERVICE 'Service_UserLog_Others_DBLOG'
ON CONTRACT Contract_CustomerLog_UserLog_Credit
WITH ENCRYPTION = OFF

-- Send messages on Dialog
SET @Message = N'Very First Message  From DBLOGBK to DBLOG';
SEND ON CONVERSATION @SBDialog
MESSAGE TYPE MessageType_CustomerLog_UserLog_Credit (@Message)

GO

--check pending messages on DBLOGBK
SELECT transmission_status,* FROM sys.transmission_queue