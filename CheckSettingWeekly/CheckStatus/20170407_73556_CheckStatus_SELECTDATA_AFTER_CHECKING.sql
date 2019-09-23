/*
	Created: 20170407@Helen
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/
USE CheckResultDB
GO

SELECT * FROM dbo.CheckStatusResult WITH (NOLOCK)

SELECT * FROM dbo.CheckStatusResult_DCS WITH (NOLOCK)