/*
	Created: Johnson
	Date: 2018-10-22
	Task: Activation procedure for 
	DB: DBLOG/bodb_CustomerLog
*/
USE bodb_CustomerLog
GO
ALTER QUEUE [Queue_UserLog_Credit]
WITH
STATUS = ON,
ACTIVATION(
			STATUS = OFF,
			PROCEDURE_NAME = [sb].QueueUserLogCredit_ProcessData,
			MAX_QUEUE_READERS = 10, -- Maximum Number of queue reader can be started at the same time
			EXECUTE AS 'dbo'
		);	