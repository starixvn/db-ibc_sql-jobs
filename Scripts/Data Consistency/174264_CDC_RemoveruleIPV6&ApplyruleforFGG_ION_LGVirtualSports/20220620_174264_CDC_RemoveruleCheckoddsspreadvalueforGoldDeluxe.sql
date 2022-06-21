/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220620@July
	Task: Remove Check oddsspread value for GoldDeluxe [Redmine:#174264]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO
DECLARE @RuleId INT, @taskId INT

SELECT @RuleId = RuleId
FROM dbo.DBA_Rules WITH(NOLOCK)
WHERE Name LIKE '%Check oddsspread value for GoldDeluxe%'

SELECT @taskId = taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @RuleId

DELETE FROM dbo.DBA_Schedules WHERE taskId = @taskId --1 rows
DELETE FROM dbo.DBA_Tasks WHERE RuleId = @RuleId --1 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @RuleId --1 row

-------Remove TASK/SCHEDULE FOR productId = 255 (GoldDeluxe)
DECLARE @tmpTaskId TABLE (taskId INT)
INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE command LIKE '%@ProductId = 255%'

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --5 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --5 rows