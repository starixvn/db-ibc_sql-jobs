/*
	Created: 20180802@Elodie
	Task: Add rules for checking PT
	DB: DBCHECK.CheckResultDB  
*/

USE CheckResultDB
GO

INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
        ([RuleId]
        ,[RuleName]
        ,[ModifiedDate])
SELECT 42,'Missing PT setting' ,GETDATE()
