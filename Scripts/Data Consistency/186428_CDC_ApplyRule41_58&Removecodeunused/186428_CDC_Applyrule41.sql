/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20230412@July
	Task: Check Data Consistency - Apply rule #41 - [Redmine:#186428]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s41 INT, @taskId_s41 INT 
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

SET @ruleId_s41 =(SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Checking data of swinlost, mwinlost, awinlost in settled ticket%')

UPDATE dbo.DBA_Rules 
SET Name = N'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets'
	,Description = N'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets'
WHERE RuleId = @ruleId_s41

UPDATE dbo.DBA_Tasks WITH(ROWLOCK,UPDLOCK)
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 1, @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
  ,@taskId_s41 = TaskId
WHERE [RuleId] = @ruleId_s41 AND command LIKE '%bettransRNG%'

UPDATE dbo.DBA_Schedules
SET Name = 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettransRNG'
	,FrequenceSubDayType =4
	,FrequenceSubdayInterval =30
WHERE TaskId = @taskId_s41

UPDATE dbo.DBA_Tasks WITH(ROWLOCK,UPDLOCK)
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 1, @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
	,@taskId_s41 = TaskId
WHERE [RuleId] = @ruleId_s41 AND command LIKE '%bettransLC%'

UPDATE dbo.DBA_Schedules
SET Name = 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettransLC'
	,FrequenceSubDayType =4
	,FrequenceSubdayInterval =30
WHERE TaskId = @taskId_s41

UPDATE dbo.DBA_Tasks WITH(ROWLOCK,UPDLOCK)
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 1, @tablename = ''bettransG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
	,@taskId_s41 = TaskId
WHERE [RuleId] = @ruleId_s41 AND command LIKE '%bettransG%'

UPDATE dbo.DBA_Schedules
SET Name = 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettransG'
	,FrequenceSubDayType =4
	,FrequenceSubdayInterval =30
WHERE TaskId = @taskId_s41


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s41, N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 1, @tablename = ''bettrans'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s41 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettrans'
 ,@TaskId = @taskId_s41
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

SELECT 'Checking data of swinlost, mwinlost, awinlost, playercomm, comm, acomm, scomm in settled tickets on table bettrans' AS RuleChecking, @ErrCode, @ErrMsg


