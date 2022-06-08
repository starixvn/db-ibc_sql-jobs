/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220608@July
	Task: Check Data Consistency - Check Member Stake/WinLost consistent among tables BettransLC, bettransRNG and Bettrans for all related products - [Redmine:#168804]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s34 INT, @taskId_s34 INT
	   ,@ruleId_s35 INT, @taskId_s35 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

SET @ruleId_s34 = (SELECT RuleId FROM dbo.DBA_Rules WITH(NOLOCK) WHERE Name LIKE '%Check Member Winlost Consistent%')

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s34, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @tablename = ''bettransRNG'', @Rule = ''winlost'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s34 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Member Winlost Consistent among tables BettransRNG and Bettrans'
 ,@TaskId = @taskId_s34
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Member Winlost Consistent among tables BettransRNG and Bettrans' AS RuleChecking, @ErrCode, @ErrMsg

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s34, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @tablename = ''bettransLC'', @Rule = ''winlost'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s34 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Member Winlost Consistent among tables BettransLC and Bettrans'
 ,@TaskId = @taskId_s34
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Member Winlost Consistent among tables BettransLC and Bettrans' AS RuleChecking, @ErrCode, @ErrMsg


/*=======================================================================================================================*/

SET @ruleId_s35 = (SELECT RuleId FROM dbo.DBA_Rules WITH(NOLOCK) WHERE Name LIKE '%Check Member Stake Consistent%')


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s35, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @tablename = ''bettransRNG'', @Rule = ''stake'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s35 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Member Stake Consistent among tables BettransRNG and Bettrans'
 ,@TaskId = @taskId_s35
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Member Stake Consistent among tables BettransRNG and Bettrans' AS RuleChecking, @ErrCode, @ErrMsg

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s35, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @tablename = ''bettransLC'', @Rule = ''stake'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s35 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Member Stake Consistent among tables BettransLC and Bettrans'
 ,@TaskId = @taskId_s35
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Member Stake Consistent among tables BettransLC and Bettrans' AS RuleChecking, @ErrCode, @ErrMsg