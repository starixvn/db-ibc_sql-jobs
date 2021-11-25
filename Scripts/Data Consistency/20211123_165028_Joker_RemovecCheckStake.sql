/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 2021123@July
	Task: Check Data Consistency - Remove check rule #3: Check stake > 0 for Joker product - [Redmine:#165028]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	 @taskId INT

SELECT  @taskId = TaskId
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = 3 AND command like '%234%'

DELETE FROM dbo.DBA_Tasks WITH(ROWLOCK) WHERE TaskId = @taskId
DELETE FROM dbo.DBA_Schedules WITH(ROWLOCK) WHERE TaskId = @taskId
