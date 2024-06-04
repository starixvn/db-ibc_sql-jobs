/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20240605@July
	Task: Support TW Team to receive notify emails for Betbuider - [Redmine: #206126]
	DB: DBCONSISTENCY-bodb_Consistency

	Note: Update email totti.chen@onelab.tw
*/

USE bodb_Consistency
GO

DECLARE @tmpTaskId TABLE (TaskId INT)

INSERT INTO @tmpTaskId(TaskId)
SELECT TaskId FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE command LIKE '%DBA_Consistency_BetBuilderResultChecking%' 

UPDATE s
SET Emails = Emails +';totti.chen@onelab.tw'
FROM dbo.DBA_Schedules s WITH(ROWLOCK, UPDLOCK)
WHERE s.TaskId IN (SELECT TaskId FROM @tmpTaskId)
