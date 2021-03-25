/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210324@July
	Task: Check Data Consistency - PP Live Casino - [Redmine: #151680]
	DB: DBCONSISTENCY-bodb_Consistency

*/

USE bodb_Consistency
GO

DECLARE	@taskId_g1 INT, @taskId_g2 INT, @taskId_g3 INT, @taskId_g4 INT, @taskId_g5 INT,
		@ruleId_g12 INT, 
		@taskId_Ph1 INT, @taskId_Pd1 INT, --PP Live Casino
		@taskId_Sh2 INT, @taskId_Sd2 INT, --SexyGaming
		@taskId_Hh3 INT, @taskId_Hd3 INT, --Habanero
		@taskId_Sh4 INT, @taskId_Sd4 INT  --SpadeGaming

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--===PP Live Casino===--
-- (*) G1: Check Discount value
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (1, N'EXEC dbo.DBA_Consistency_DiscountChecking @ProductId = 170,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g1 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Discount value'
 ,@TaskId = @taskId_g1
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Discount value' AS RuleChecking, @ErrCode, @ErrMsg
---------------------------------------------------------------------------------
-- (*) G2: Check PT value
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (2, N'EXEC dbo.DBA_Consistency_PTChecking @ProductId = 170, @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g2 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT value'
 ,@TaskId = @taskId_g2
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check PT value' AS RuleChecking, @ErrCode, @ErrMsg
---------------------------------------------------------------------------------
-- (*) G3: Check Stake >0 for dedicated bettypes
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (3, N'EXEC dbo.DBA_Consistency_StakeChecking @ProductId = 170, @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g3 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Stake >0 for dedicated bettypes'
 ,@TaskId = @taskId_g3
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

 SELECT 'Check Stake >0 for dedicated bettypes' AS RuleChecking, @ErrCode, @ErrMsg
 ---------------------------------------------------------------------------------
 -- (*) G4: Check Valid IP
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (4, N'EXEC dbo.DBA_Consistency_IPChecking @ProductId = 170,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g4 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Valid IP'
 ,@TaskId = @taskId_g4
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check Valid IP' AS RuleChecking, @ErrCode, @ErrMsg
---------------------------------------------------------------------------------
-- (*) G5: Check all yesterday tickets must be settled
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (5, N'EXEC dbo.DBA_Consistency_StatusChecking @ProductId = 170, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g5 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check all yesterday tickets must be settled'
 ,@TaskId = @taskId_g5
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check all yesterday tickets must be settled' AS RuleChecking, @ErrCode, @ErrMsg


--(*)====================================================================================(*)--
-- (*) G12: Check tickets in bettransRNG/BettransLC are sum to bettrans
--(*) PP Live Casino
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check tickets in bettransRNG/BettransLC are sum to bettrans', N'Alert if ticket in bettransRNG/bettransLC with transdate - current date > 15 minutes and IsSum = 1', N'High')
SET @ruleId_g12 = SCOPE_IDENTITY()
--Hour
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 170, @Duration = ''hour'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Ph1 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly'
 ,@TaskId = @taskId_Ph1
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly' AS RuleChecking, @ErrCode, @ErrMsg

--Daily
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 170, @Duration = ''lastday'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Pd1 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily'
 ,@TaskId = @taskId_Pd1
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily' AS RuleChecking, @ErrCode, @ErrMsg

--(*) SexyGaming

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 243, @Duration = ''hour'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Sh2 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly'
 ,@TaskId = @taskId_Sh2
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly' AS RuleChecking, @ErrCode, @ErrMsg

--Daily
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 243, @Duration = ''lastday'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Sd2 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily'
 ,@TaskId = @taskId_Sd2
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily' AS RuleChecking, @ErrCode, @ErrMsg

--(*) Habanero
--Hour
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 238, @Duration = ''hour'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Hh3 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly'
 ,@TaskId = @taskId_Hh3
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly' AS RuleChecking, @ErrCode, @ErrMsg

--Daily
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 238, @Duration = ''lastday'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Hd3 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily'
 ,@TaskId = @taskId_Hd3
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily' AS RuleChecking, @ErrCode, @ErrMsg

--(*) SpadeGaming
--Hour
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 247, @Duration = ''hour'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Sh4 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly'
 ,@TaskId = @taskId_Sh4
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - hourly' AS RuleChecking, @ErrCode, @ErrMsg

--Daily
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g12, N'EXEC dbo.DBA_Consistency_TicketSettledSumChecking @ProductId = 247, @Duration = ''lastday'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_Sd4 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily'
 ,@TaskId = @taskId_Sd4
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-24'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets in bettransRNG/BettransLC are sum to bettrans - daily' AS RuleChecking, @ErrCode, @ErrMsg



