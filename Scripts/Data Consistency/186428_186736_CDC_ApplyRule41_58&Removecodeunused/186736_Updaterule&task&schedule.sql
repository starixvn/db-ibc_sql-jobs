/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20230420@July
	Task: Check Data Consistency - Update rule/task/schedule- [Redmine: #186736]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO
DECLARE	@ruleId INT, @taskId INT 
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

--------Update schedule rule #56
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check if tickets in translog are settled to bettrans correspondently%')

SELECT @taskId = taskId 
FROM dbo.DBA_Tasks WITH(NOLOCK) 
WHERE RuleId = @ruleId

UPDATE dbo.DBA_Schedules 
SET Name = 'Check if tickets in translog are settled to bettrans correspondently'
WHERE taskId = @taskId 

--------Update taskId (bị nhầm rule :(( )
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check stake value%')

UPDATE DBA_Tasks --2 rows
SET RuleId =3 
WHERE RuleId = @ruleId AND command LIKE '%DBA_Consistency_StakeChecking%'

--------Update check winlost/stake về rule #34 & #35 
SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check Member Winlost Consistent%')

UPDATE DBA_Tasks --1 rows
SET RuleId = @ruleId, @taskId = taskId
WHERE RuleId = 13 AND command LIKE '%241%'

UPDATE DBA_Schedules --1 rows
SET Name = 'Check Member Winlost Consistent'
, FrequenceSubDayType = 1
, FrequenceSubdayInterval = 0
, ActiveStartTime ='00:30'
WHERE TaskId = @taskId


SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check Member Stake Consistent%')

UPDATE DBA_Tasks --1 rows
SET RuleId = @ruleId, @taskId = taskId
WHERE RuleId = 14 AND command LIKE '%241%'

UPDATE DBA_Schedules --1 rows
SET Name = 'Check Member Stake Consistent'
, FrequenceSubDayType = 1
, FrequenceSubdayInterval = 0
, ActiveStartTime ='00:30'
WHERE TaskId = @taskId


DELETE FROM DBA_Rules WHERE RuleId IN (13,14)

--------Update change rule #15 chung SP rule #58
UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_GeneralRules_bettransRNGChecking @CheckMode = 3, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
  , @taskId = taskId
  , @ruleId = RuleId
WHERE command like '%DBA_Consistency_TicketSettledSumChecking%' 

UPDATE DBA_Schedules --1 rows
SET Name = 'Settled ticket in bettransRNG are not yet summed to bettrans'
WHERE TaskId = @taskId


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId, N'EXEC dbo.DBA_Consistency_GeneralRules_bettransLCChecking @CheckMode = 3, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Settled ticket in bettransLC are not yet summed to bettrans'
 ,@TaskId = @taskId
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Settled ticket in bettransLC are not yet summed to bettrans' AS RuleChecking, @ErrCode, @ErrMsg

--------Update change rule #43 vào chung SP #58
UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_GeneralRules_bettransRNGChecking @CheckMode = 4, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
WHERE command like '%DBA_Consistency_DetectNetstakeforRNGChecking%' 

--------Update change rule #7 chung SP rule ##41

SET @ruleId = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Check rule actual_stake, winlost, playercomm%')

UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 2, @tablename = ''bettrans'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
WHERE RuleId = @ruleId AND command like '%bettrans%' 

UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 2, @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
WHERE RuleId = @ruleId AND command like '%bettransRNG%' 

UPDATE dbo.DBA_Tasks
SET command = N'EXEC dbo.DBA_Consistency_WinlostCommChecking @CheckMode = 2, @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT'
WHERE RuleId = @ruleId AND command like '%bettransLC%' 
