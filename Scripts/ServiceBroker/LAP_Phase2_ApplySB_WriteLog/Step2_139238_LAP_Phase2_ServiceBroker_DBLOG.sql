/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBLOG/bodb_CustomerLog
*/
USE [bodb_CustomerLog]
GO

CREATE MESSAGE TYPE [MessageType_CustomerLog_UserLog_RunSP]

CREATE CONTRACT [Contract_CustomerLog_UserLog_RunSP] AUTHORIZATION [dbo] 
([MessageType_CustomerLog_UserLog_RunSP] SENT BY ANY)

ALTER SERVICE [Service_UserLog_Others_DBLOG]
(ADD CONTRACT [Contract_CustomerLog_UserLog_RunSP]) 

