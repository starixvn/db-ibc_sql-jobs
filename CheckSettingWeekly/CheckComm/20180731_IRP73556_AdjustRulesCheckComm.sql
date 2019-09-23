/*
	Created: 20180731@Elodie
	Task: Adjust rules for checking commission
	DB: DBCHECK.CheckResultDB  
*/

USE CheckResultDB
GO
SELECT * FROM dbo.Rule_Credit WITH (NOLOCK)
  
GO
UPDATE r
SET RuleId = RuleId + 65
FROM dbo.Rule_Credit r
WHERE RuleId BETWEEN 36 AND 41

GO
INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
        ([RuleId]
        ,[RuleName]
        ,[ModifiedDate])
SELECT 107,'Super''s Discount <> Super''s Discount on member level' ,GETDATE()
UNION SELECT 108,'Master''s Discount <> Master''s Discount on member level',GETDATE()   
UNION SELECT 109,'Agent''s Discount <> Agent''s Discount on member level',GETDATE() 