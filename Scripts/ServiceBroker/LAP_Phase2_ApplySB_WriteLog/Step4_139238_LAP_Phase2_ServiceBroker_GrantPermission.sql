/*<info serverAlias="DBCUST-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBCUST/bodb_CustomerLog

	
*/
USE bodb_CustomerLog
GO
GRANT EXEC ON sb.CustomerLog_SendMessage TO [bodbLicenseeNet]