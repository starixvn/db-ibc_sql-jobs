/*
	Created: 20181211@Helen
	Task: Update email info - https://nexdev.net/issues/106941
	DB: DBTP/bodb_Consistency

*/
USE bodb_Consistency
GO
UPDATE s
	SET Emails = 'dbaadmin@starixsoft.com'
FROM dbo.DBA_Schedules s WITH (ROWLOCK)
GO 
