/*<info serverAlias="dblog-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: dblog/bodb_CustomerLog

	
*/
-- dblog/bodb_customerlog
-- Step 1:
SELECT CONVERT(NVARCHAR(MAX), message_body) AS Message  FROM [Queue_Others]
GO
-- Send messages on Dialog
RECEIVE TOP (1) @Message = message_body 
FROM [Queue_Others];
GO


