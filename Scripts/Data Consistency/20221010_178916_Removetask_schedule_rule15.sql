/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20221010@July
	Task: Check Data Consistency - Remove schedule hour rule #15- [Redmine:#178916]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	 @taskId INT

SELECT  @taskId = TaskId
FROM dbo.DBA_Tasks WITH(NOLOCK)
WHERE command like '%EXEC dbo.DBA_Consistency_TicketSettledSumChecking @Duration = ''hour''%' 

DELETE FROM dbo.DBA_Tasks WITH(ROWLOCK) WHERE TaskId = @taskId
DELETE FROM dbo.DBA_Schedules WITH(ROWLOCK) WHERE TaskId = @taskId
