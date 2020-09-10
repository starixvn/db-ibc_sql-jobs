/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBLOG/bodb_CustomerLog
*/
USE bodb_CustomerLog
GO
ALTER TABLE UserLog_RunSP 
ADD CreatedDate DATETIME NULL




