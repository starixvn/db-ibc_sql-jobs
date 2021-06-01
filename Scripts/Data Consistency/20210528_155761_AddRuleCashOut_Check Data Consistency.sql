/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210528@July
	Task: Check Cashout apply for Sportbook [Redmine:#155761]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s35 INT, @taskId_s1 INT, @taskId_s2 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S35 - Add rules for Cashout
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Check tickets Cashout for Sportbook', N'Check tickets Cashout for Sportbook', N'High')

SET @ruleId_s35 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s35, N'EXEC dbo.DBA_Consistency_CashoutChecking @ProductId = 1, @Rule = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s1 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check if main bet ticket is Voided/Rejected, ticket 911 and Dummy Cashout BetTicket, 912, 913 need have status Voided/Rejected'
 ,@TaskId = @taskId_s1
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-05-31' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:15'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check if main bet ticket is Voided/Rejected, ticket 911 and Dummy Cashout BetTicket, 912, 913 need have status Voided/Rejected' AS RuleChecking, @ErrCode, @ErrMsg


INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s35, N'EXEC dbo.DBA_Consistency_CashoutChecking @ProductId = 1, @Rule = 2, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s2 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check if Cashout ticket 911 is Voided related tickets (Dummy CashOut Bet Ticket, ticket 912, 913) need have status Voided'
 ,@TaskId = @taskId_s2
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-05-31' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:15'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Check if Cashout ticket 911 is Voided related tickets (Dummy CashOut Bet Ticket, ticket 912, 913) need have status Voided' AS RuleChecking, @ErrCode, @ErrMsg
