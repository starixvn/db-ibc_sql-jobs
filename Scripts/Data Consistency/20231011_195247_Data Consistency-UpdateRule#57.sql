/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20231011@July
	Task: Data Consistency - Update Rule #57 - [Redmine:#195247]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s45 INT, @taskId_s45 INT
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

SELECT @taskId_s45 = TaskId 
FROM dbo.DBA_Tasks WITH(NOLOCK)
WHERE command LIKE '%DBA_Consistency_DetectNetstakeforDrawticket%'
	AND command like '%checkmode = 3%'

DELETE FROM dbo.DBA_Tasks WHERE TaskId = @taskId_s45 --1 row
DELETE FROM dbo.DBA_Schedules WHERE TaskId = @taskId_s45 --1 row


SELECT @ruleId_s45 = RuleId
FROM dbo.DBA_Rules WITH(NOLOCK)
WHERE Name LIKE '%Detect netstake <> 0 for Draw ticket%'

/* YeeBet - 159 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 159, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s45 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Detect draw tickets have bettransLC.netstake <> 0'
 ,@TaskId = @taskId_s45
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg