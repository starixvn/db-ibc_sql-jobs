/*
	Created: JOhnson
	Date: 2017-12-15
	Task: add more rule to check status 
	DB: DBCHECK/[CheckResultDB]
*/
INSERT INTO [CheckResultDB].[dbo].[CheckSetting_ProductStatusRule]
           ([RuleID]
           ,[RuleName])
SELECT 13, 'Super IsSync= 0 (For GD,CS,VB,AB)'
UNION SELECT 14, 'Master IsSync= 0 (For GD,CS,VB,AB)'
UNION SELECT 15, 'Agent IsSync= 0 (For GD,CS,VB,AB)'
UNION SELECT 16, 'Member IsSync= 0 (For GD,CS,VB,AB)'