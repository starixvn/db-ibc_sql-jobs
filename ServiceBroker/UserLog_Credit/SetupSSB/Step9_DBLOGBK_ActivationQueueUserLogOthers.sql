/*
	Created: Johnson
	Date: 2018-11-14
	Task: Activation procedure for 
	DB: DBLOGBK/bodb_CustomerLog
*/
USE bodb_CustomerLog
GO
ALTER QUEUE [Queue_Others]
WITH
STATUS = ON,
ACTIVATION(
			STATUS = ON,
			PROCEDURE_NAME = [sb].QueueOthersDBLOG_ProcessData,
			MAX_QUEUE_READERS = 10, -- Maximum Number of queue reader can be started at the same time
			EXECUTE AS 'dbo'
		);	