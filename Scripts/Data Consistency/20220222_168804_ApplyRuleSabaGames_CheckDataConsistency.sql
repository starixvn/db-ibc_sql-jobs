/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220222@July
	Task: Check Data Consistency - Apply for Saba.games - bettype 1651 (Hi-Lo) - [Redmine:#168804]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s9 INT, @taskId_s9 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

SET @ruleId_s9 = (SELECT RuleId FROM dbo.DBA_Rules WITH(NOLOCK) WHERE Name LIKE '%Check all today tickets running > 30 minutes must be settled%')

UPDATE [DBA_Tasks]
SET command = N'EXEC dbo.DBA_Consistency_OtherSportsStatusChecking @tablename = ''bettrans'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
WHERE [RuleId] = @ruleId_s9


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s9, N'EXEC dbo.DBA_Consistency_OtherSportsStatusChecking @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s9 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check all today tickets running > 30 minutes must be settled'
 ,@TaskId = @taskId_s9
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 4 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 30 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check all today tickets running > 30 minutes must be settled' AS RuleChecking, @ErrCode, @ErrMsg
