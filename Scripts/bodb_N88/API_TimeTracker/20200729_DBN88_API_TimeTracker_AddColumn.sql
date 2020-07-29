/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20200729@Percy
	DB: DBN88-bodb_N88
	Task: Add new column KeyValue on API_TimeTracker
*/
USE bodb_N88
GO

ALTER TABLE dbo.API_TimeTracker
	ADD KeyValue VARCHAR(50) NULL
GO