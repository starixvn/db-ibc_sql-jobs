/*
	Created: 20170929@Johnson
	Task: Add more rules for checking commission
	DB: DBCHECK.CheckResultDB  
*/


INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
 SELECT 44,'Super''s Discount <> Super''s Discount on member level' ,GETDATE()
 UNION SELECT 45,'Master''s Discount <> Master''s Discount on member level',GETDATE()   
 UNION SELECT 46,'Agent''s Discount <> Agent''s Discount on member level',GETDATE()   