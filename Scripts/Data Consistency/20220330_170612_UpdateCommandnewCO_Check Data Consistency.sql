/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220330@July
	Task: Check Data Consistency - Update command 'Detect Cashout ticket with WinLoseDate > current date + 1' - [Redmine:#170612]
	DB: DBCONSISTENCY-bodb_Consistency

*/
DECLARE	@ruleId_s42 INT, @taskId_s42 INT
SET @ruleId_s42 = (SELECT RuleId FROM dbo.DBA_Rules WITH (NOLOCK) WHERE Name LIKE '%Detect Cashout ticket (with Betdaqid = -2) and WinloseDate > current day%')

SELECT @taskId_s42 = TaskId
FROM dbo.DBA_Tasks WITH (NOLOCK)
WHERE RuleId = @ruleId_s42

UPDATE dbo.DBA_Schedules WITH(ROWLOCK,UPDLOCK)
SET Name = N'Detect Cashout ticket with WinLoseDate > current date + 1'
WHERE TaskId = @taskId_s42

UPDATE dbo.DBA_Rules WITH(ROWLOCK,UPDLOCK)
SET Name = N'Detect Cashout ticket with WinLoseDate > current date + 1'
   ,[Description] = N'Detect Cashout ticket with WinLoseDate > current date + 1'
WHERE [RuleId] = @ruleId_s42
