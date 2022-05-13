/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220509@July
	Task: Check Data Consistency - Remove rule - [Redmine: #172310]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE @tmpTaskId TABLE (taskId INT)

INSERT INTO @tmpTaskId (taskId)
SELECT taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE command like '%DBA_Consistency_StatusChecking %' 
AND command not like '%DBA_Consistency_StatusChecking @ProductId = 1, @Bettype = 38%' 

DELETE FROM dbo.DBA_Schedules WHERE taskId IN( SELECT taskId FROM @tmpTaskId)
DELETE FROM dbo.DBA_Tasks WHERE taskId IN( SELECT taskId FROM @tmpTaskId)



