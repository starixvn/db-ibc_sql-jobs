/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20201221@July
	Task: God of Fortune - Check Data Consistency [Redmine:#147246]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s33 INT, @taskId_s33 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S33 - Add rule for tickets of God of Fortune (GoF)
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check tickets of God of Fortune', N'Check tickets of GoF have actual_stake equal stake matchid = 29, bettype = 29, oddsspread = 1, ticket status = all statuses', N'High')

SET @ruleId_s33 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s33, N'EXEC dbo.DBA_Consistency_GodofFortuneChecking @ProductId = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s33 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check tickets of God of Fortune'
 ,@TaskId = @taskId_s33
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2020-12-28' 
 ,@ActiveEndDate = '2021-02-01'
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = '23:59'
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check tickets of God of Fortune' AS RuleChecking, @ErrCode, @ErrMsg





