/*
	Created: 20200818@Johnson
	Task: insert new rule for checking stakelevel duplicates
	DB: DBCHECK.CheckResultDB
*/

INSERT INTO [dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 307, 'Duplicated stakelevel', GETDATE()

