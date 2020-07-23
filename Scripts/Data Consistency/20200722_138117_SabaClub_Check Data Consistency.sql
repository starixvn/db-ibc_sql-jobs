/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20200722@Max
	Task: Saba.club - Check Data Consistency - [Redmine:#138117]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s31 INT, @taskId_s31 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S30 - Running ticket with transdate + 3 minutes > current time 
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Running ticket with transdate + 25 hours > current time', N'Running ticket with transdate + 25 hours > current time', N'High')

SET @ruleId_s31 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s31, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 200, @Rule = ''25h'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s31 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Running ticket with transdate + 25 hours > current time'
 ,@TaskId = @taskId_s31
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2020-07-23' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'max.tran@starixsoft.com;gary.vu@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Running ticket with transdate + 25 hours > current time' AS RuleChecking, @ErrCode, @ErrMsg





