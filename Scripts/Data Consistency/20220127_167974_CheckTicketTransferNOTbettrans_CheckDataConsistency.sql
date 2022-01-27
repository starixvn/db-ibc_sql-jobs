/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220127@July
	Task: Check Data Consistency - Check ticket transfer is not in bettrans [Redmine:#167974]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_g13 INT, @taskId_g13 INT
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)


INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check ticket transfer is not in bettrans', N'Alert if ticket with bettype >= 19999 exist in bettrans', N'High')

SET @ruleId_g13 = SCOPE_IDENTITY()

--HOUR
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g13, N'EXEC dbo.DBA_Consistency_TicketTransferChecking @Duration = ''hour'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_g13 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check ticket transfer is not in bettrans - hourly'
 ,@TaskId = @taskId_g13
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

SELECT 'Check ticket transfer is not in bettrans - hourly' AS RuleChecking, @ErrCode, @ErrMsg

--DAILY
INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_g13, N'EXEC dbo.DBA_Consistency_TicketTransferChecking @Duration = ''lastday'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_g13 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check ticket transfer is not in bettrans - daily'
 ,@TaskId = @taskId_g13
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

SELECT 'Check ticket transfer is not in bettrans - daily' AS RuleChecking, @ErrCode, @ErrMsg