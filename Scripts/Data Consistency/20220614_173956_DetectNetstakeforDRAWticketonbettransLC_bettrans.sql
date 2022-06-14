/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220614@July
	Task: Data Consistency - Detect Netstake <> 0 for Draw ticket [Redmine:#173956]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s45 INT, @taskId_s45 INT
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S45 -  Detect netstake <> 0 for Draw ticket
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Detect netstake <> 0 for Draw ticket', N'Detect netstake <> 0 for Draw ticket', N'High')

SET @ruleId_s45 = SCOPE_IDENTITY()

/* Allbet - 211 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 211, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg

/* AE Sexy - 243 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 243, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg

/* IBCBet Live Casino - 242 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 242, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg

/* WM - 233 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 233, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg

/* BG (Big Gaming) - 239 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 239, @CheckMode = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettransLC.netstake <> 0' AS RuleChecking, @ErrCode, @ErrMsg

/* Bettype game DragonTiger, Roulette, Sicbo of above LC products */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @CheckMode = 2, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s45 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Detect draw tickets for bettype game DragonTiger, Roulette, Sicbo of LC products'
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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets for bettype game DragonTiger, Roulette, Sicbo of LC products' AS RuleChecking, @ErrCode, @ErrMsg

/* Virtual Sports 3 (Leap Gaming) - 231 */
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s45, N'EXEC dbo.DBA_Consistency_DetectNetstakeforDrawticket @ProductId = 231, @CheckMode = 3, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s45 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Detect draw tickets have bettrans.oddsspread <> 0'
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
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect draw tickets have bettrans.oddsspread <> 0' AS RuleChecking, @ErrCode, @ErrMsg

