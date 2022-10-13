/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20221013@July
	Task: Data Consistency - Check if tickets in translog are settled to bettrans correspondently [Redmine:#179020]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId INT, @taskId INT
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check if tickets in translog are settled to bettrans correspondently', N'Check if tickets in translog are settled to bettrans correspondently', N'High')

SET @ruleId = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @tablename = ''translog'', @Rule = ''compare_ticket'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Settled tickets in translog but having more than one ticket in bettrans'
 ,@TaskId = @taskId
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = @Today
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:15'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
--,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Settled tickets in translog but having more than one ticket in bettrans' AS RuleChecking, @ErrCode, @ErrMsg

