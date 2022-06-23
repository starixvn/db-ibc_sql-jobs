/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220620@July
	Task: Remove rule IPV6 & remove rule un-used [Redmine:#174264]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO
DECLARE @RuleId INT

SELECT @RuleId = RuleId
FROM dbo.DBA_Rules WITH(NOLOCK)
WHERE Name LIKE '%Check Valid IP%'

DECLARE @tmpTaskId TABLE (taskId INT)

INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @RuleId

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId) --27 rows
DELETE FROM dbo.DBA_Tasks WHERE RuleId = @RuleId --27 rows
DELETE FROM dbo.DBA_Rules WHERE RuleId = @RuleId --1 row

DROP PROCEDURE [dbo].[DBA_Consistency_IPChecking]
DROP PROCEDURE [dbo].[DBA_Consistency_IPChecking_NotDelegateMatchId]

----- Remove un-used rules
DECLARE @tmpRuleId TABLE (RuleId INT)
INSERT INTO @tmpRuleId (RuleId)
SELECT RuleId
FROM dbo.DBA_Rules WITH(NOLOCK)
WHERE (
		Name LIKE '%Check oddsspread value'
	OR	Name LIKE '%Check modds value'
	OR	Name LIKE '%Check comm value'
	OR	Name LIKE '%Check sma winlost values'
	OR	Name LIKE '%Check hdp2 value'
	OR	Name LIKE '%Check transid2 value'
)

DELETE FROM dbo.DBA_Rules WHERE RuleId IN (SELECT RuleId FROM @tmpRuleId) --6 rows