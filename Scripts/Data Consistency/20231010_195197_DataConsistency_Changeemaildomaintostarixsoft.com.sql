/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20231010@July
	Task: Data Consistency - Change email domain to starixsoft.com - [Redmine: #195197]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO
UPDATE dbo.DBA_Schedules WITH (ROWLOCK, UPDLOCK)
SET  Emails = 'dbaadmin@starixsoft.com'
WHERE Emails = 'dbaadmin@starixvn.com'