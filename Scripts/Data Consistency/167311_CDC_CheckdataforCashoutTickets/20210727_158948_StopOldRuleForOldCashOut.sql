/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220112@July
	Task: Check Data Consistency - Stop old rule for Old Cashout - [Redmine:#167311]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@RuleId INT
DECLARE @tmpTaskId TABLE (TaskId INT)

SELECT  @RuleId = RuleId
FROM dbo.DBA_Rules WITH(NOLOCK) 
WHERE Name like '%Check tickets Cashout for Sportbook%'
select @RuleId

INSERT INTO @tmpTaskId(TaskId)
SELECT TaskId
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @RuleId

DELETE FROM dbo.DBA_Schedules WITH(ROWLOCK) WHERE TaskId IN (SELECT TaskId FROM @tmpTaskId)
DELETE FROM dbo.DBA_Tasks WITH(ROWLOCK) WHERE RuleId = @RuleId
DELETE FROM dbo.DBA_Rules WITH(ROWLOCK) WHERE RuleId = @RuleId
GO
DROP PROCEDURE dbo.DBA_Consistency_CashoutChecking
GO
