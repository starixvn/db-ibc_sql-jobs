/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210223@Danny
	Task: Check Data Consistency - ExtraPT [Redmine:#125883]
	DB: DBCONSISTENCY-bodb_Consistency

*/

USE bodb_Consistency
GO


DELETE t 
FROM  [dbo].[DBA_Tasks] t  WITH(ROWLOCK) WHERE TaskId IN (141,142,143,144,145,146)

DELETE t 
FROM  [dbo].[DBA_Rules] t  WITH(ROWLOCK) WHERE RuleId = 36

