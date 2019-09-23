/*
	Created: 20190610@Johnson	
	Task: add more rule to check status  for suspend info
	DB: DBCHECK/[CheckResultDB]
*/
INSERT INTO [CheckResultDB].[dbo].[DBA_CheckSetting_ProductStatusRule]
           ([RuleID]
           ,[RuleName])
SELECT 17, 'Suspend status in-consitency with suspend info'

INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 36, 'dummy super has S3<>0', getdate()
UNION SELECT 37, 'dummy super has S1<>0', getdate()		   