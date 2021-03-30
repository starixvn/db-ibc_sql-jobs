/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210324@July
	Task: Check Data Consistency - Sports Lottery - [Redmine: #151680]
	DB: DBCONSISTENCY-bodb_Consistency

*/

USE bodb_Consistency
GO

DECLARE	@taskId_g1 INT, @taskId_g2 INT, @taskId_g3 INT, @taskId_g4 INT, @taskId_g5 INT,
		@taskId_s32 INT, @taskId_s33 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--===Sports Lottery===--
-- (*) G1: Check Discount value
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (1, N'EXEC dbo.DBA_Consistency_DiscountChecking @ProductId = 169,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g1 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Discount value'
 ,@TaskId = @taskId_g1
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29' 
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
VALUES (2, N'EXEC dbo.DBA_Consistency_PTChecking @ProductId = 169,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g2 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT value'
 ,@TaskId = @taskId_g2
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29' 
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
VALUES (3, N'EXEC dbo.DBA_Consistency_StakeChecking @ProductId = 169,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g3 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Stake >0 for dedicated bettypes'
 ,@TaskId = @taskId_g3
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29' 
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
VALUES (4, N'EXEC dbo.DBA_Consistency_IPChecking @ProductId = 169,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g4 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Valid IP'
 ,@TaskId = @taskId_g4
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29'
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
VALUES (5, N'EXEC dbo.DBA_Consistency_StatusChecking @ProductId = 169,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_g5 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check all yesterday tickets must be settled'
 ,@TaskId = @taskId_g5
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check all yesterday tickets must be settled' AS RuleChecking, @ErrCode, @ErrMsg
---------------------------------------------------------------------------------
-- (*) S32: Settled tickets in translog but not having in bettrans
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (32, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 169, @Rule = ''translog'',@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_s32 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Settled tickets in translog but not having in bettrans'
 ,@TaskId = @taskId_s32
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Settled tickets in translog but not having in bettrans' AS RuleChecking, @ErrCode, @ErrMsg
---------------------------------------------------------------------------------
-- (*) S33: Wrong discount or comm value
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (33, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 169,@Rule = ''no_discount_comm'',@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId_s33 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Wrong discount or comm value'
 ,@TaskId = @taskId_s33
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-03-29'
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Wrong discount or comm value' AS RuleChecking, @ErrCode, @ErrMsg

