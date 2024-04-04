/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20240312@July
	Task: Check PT rules of customer for 3rd products - Rule #60 - [Redmine:#200454]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s60 INT, @taskId_s60 INT
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)


INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check PT setting of customer for 3rd products', N'Check PT setting ticket of yesterday = current PT setting of customer (get reference bet type setting in SportsBetTypeSettingMatrix, compare PT setting with PT in ticket)', N'High')

SET @ruleId_s60 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s60, N'EXEC dbo.DBA_Consistency_PTChecking_NonSports @tablename = ''bettrans'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s60 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT setting of customer for 3rd products'
 ,@TaskId = @taskId_s60
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
 --,@Emails = 'dba_local@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check PT setting of customer for 3rd products - bettrans' AS RuleChecking, @ErrCode, @ErrMsg


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s60, N'EXEC dbo.DBA_Consistency_PTChecking_NonSports @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s60 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT setting of customer for 3rd products'
 ,@TaskId = @taskId_s60
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
 --,@Emails = 'dba_local@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check PT setting of customer for 3rd products - bettransLC' AS RuleChecking, @ErrCode, @ErrMsg


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s60, N'EXEC dbo.DBA_Consistency_PTChecking_NonSports @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s60 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT setting of customer for 3rd products'
 ,@TaskId = @taskId_s60
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
 --,@Emails = 'dba_local@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check PT setting of customer for 3rd products - bettransRNG' AS RuleChecking, @ErrCode, @ErrMsg