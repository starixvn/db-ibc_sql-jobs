/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DB054 (dblog_bk)/bodb_CustomerLog; 
	
*/	

-- Step 1:
SELECT CONVERT(NVARCHAR(MAX), message_body) AS Message FROM QUEUE_DBLOG_BK ;

-- if exist messsage from this queue, we will continue to receive message and send to dblog bk
-- Send messages on Dialog
RECEIVE TOP (1) * 
FROM QUEUE_DBLOG_BK

