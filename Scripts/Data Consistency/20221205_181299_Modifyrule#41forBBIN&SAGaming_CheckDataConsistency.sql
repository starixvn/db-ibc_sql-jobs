/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20221205@July
	Task: Check Data Consistency - Modify rule #41 for BBIN & SA Gaming - [Redmine:#181299]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s41 INT, @taskId_s41 INT 
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

UPDATE dbo.DBA_Rules 
SET Name = N'Checking data of swinlost, mwinlost, awinlost in settled ticket'
	,Description = N'Checking data of swinlost, mwinlost, awinlost in settled ticket'
	,@ruleId_s41 = RuleId
WHERE Name LIKE '%Checking data of swinlost, mwinlost, swinlost in settled ticket%'


DECLARE @tmpTaskId TABLE (TaskId INT)
INSERT INTO @tmpTaskId(TaskId)
SELECT TaskId FROM dbo.DBA_Tasks WITH(NOLOCK) WHERE [RuleId] = @ruleId_s41

UPDATE dbo.DBA_Schedules
SET Name = 'Checking data of swinlost, mwinlost, awinlost in settled ticket'
WHERE TaskId IN (SELECT TaskId FROM @tmpTaskId)

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s41, N'EXEC dbo.DBA_Consistency_CheckWinlost3rd @tablename = ''bettransG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s41 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Checking data of swinlost, mwinlost, awinlost in settled ticket'
 ,@TaskId = @taskId_s41
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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Checking data of swinlost, mwinlost, awinlost in settled ticket' AS RuleChecking, @ErrCode, @ErrMsg


