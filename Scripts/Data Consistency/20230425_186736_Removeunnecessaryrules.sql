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

DECLARE @tmpTaskId TABLE (taskId INT)

INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --2 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --2 rows

-----------Remove rule #37 and related to ProductId = 223 Indo 4D(Togel 4D)
DELETE FROM @tmpTaskId

INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE command LIKE '%223%'

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --4 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --4 rows

-----------Remove rule #40
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check tickets of God of Fortune%')

SELECT @taskId = taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId = @taskId --1 rows
DELETE FROM dbo.DBA_Tasks WHERE RuleId = @ruleId --1 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @ruleId --1 rows

-----------Remove rule #18
DELETE FROM @tmpTaskId
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Settled tickets in translog but not having in bettrans%')

INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --3 rows
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --3 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @ruleId --1 rows

--------Update schedule rule #56
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check if tickets in translog are settled to bettrans correspondently%')

SELECT @taskId = taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

UPDATE dbo.DBA_Schedules 
SET Name = 'Check if tickets in translog are settled to bettrans correspondently'
WHERE taskId = @taskId 

--------Update taskId (bị nhầm rule :(( )
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check stake value%')

UPDATE DBA_Tasks --2 rows
SET RuleId =3 
WHERE RuleId = @ruleId AND command LIKE '%DBA_Consistency_StakeChecking%'

--------Update check winlost/stake về rule #34 & #35 
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check Member Winlost Consistent%')

UPDATE DBA_Tasks --1 rows
SET RuleId = @ruleId, @taskId = taskId
WHERE RuleId = 13 AND command LIKE '%241%'

UPDATE DBA_Schedules --1 rows
SET Name = 'Check Member Winlost Consistent'
, FrequenceSubDayType = 1
, FrequenceSubdayInterval = 0
, ActiveStartTime ='00:30'
WHERE TaskId = @taskId


SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check Member Stake Consistent%')

UPDATE DBA_Tasks --1 rows
SET RuleId = @ruleId, @taskId = taskId
WHERE RuleId = 14 AND command LIKE '%241%'

UPDATE DBA_Schedules --1 rows
SET Name = 'Check Member Stake Consistent'
, FrequenceSubDayType = 1
, FrequenceSubdayInterval = 0
, ActiveStartTime ='00:30'
WHERE TaskId = @taskId


DELETE FROM DBA_Rules WHERE RuleId IN (13,14)

--------Update change rule 
UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_GeneralRules_bettransRNGChecking @CheckMode = 3, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
WHERE command like '%DBA_Consistency_DetectNetstakeforRNGChecking%' 
