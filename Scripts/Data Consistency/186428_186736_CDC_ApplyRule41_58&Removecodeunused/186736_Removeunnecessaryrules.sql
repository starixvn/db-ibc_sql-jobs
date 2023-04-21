/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20230420@July
	Task: Check Data Consistency - Remove rule - [Redmine: #186736]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO
DECLARE	@ruleId INT, @taskId INT 
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

-----------Remove rule #39
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Running ticket with transdate + 25 hours > current time%')

CREATE TABLE #tmpTaskId (taskId INT)

INSERT INTO #tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --2 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --2 rows

-----------Remove rule #37 and related to ProductId = 223 Indo 4D(Togel 4D)
TRUNCATE TABLE #tmpTaskId

INSERT INTO #tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE command LIKE '%223%'

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --4 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --4 rows

-----------Remove rule #40
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check tickets of God of Fortune%')

SELECT @taskId = taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId = @taskId --1 rows
DELETE FROM dbo.DBA_Tasks WHERE RuleId = @ruleId --1 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @ruleId --1 rows

-----------Remove rule #18
TRUNCATE TABLE #tmpTaskId
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Settled tickets in translog but not having in bettrans%')

INSERT INTO #tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --3 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --3 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @ruleId --1 rows

-----------Remove rule #27
TRUNCATE TABLE #tmpTaskId
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check un-launched sites%')

INSERT INTO #tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --6 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM #tmpTaskId) --6 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @ruleId --1 rows



DROP TABLE #tmpTaskId;