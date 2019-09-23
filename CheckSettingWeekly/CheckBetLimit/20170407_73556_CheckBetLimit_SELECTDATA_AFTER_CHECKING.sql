/*
	Created: 20170407@Helen
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/
USE CheckResultDB
GO

SELECT * FROM dbo.CheckBetLimitResult WITH (NOLOCK)

SELECT * FROM dbo.CheckBetLimitResult_DCS WITH (NOLOCK)