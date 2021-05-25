/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210524@July
	Task: Saba.club - Check winlost - Check Data Consistency - [Redmine:#155714]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s34 INT, @taskId_s34 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S30 - Running ticket with transdate + 3 minutes > current time 
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Checking data of swinlost, mwinlost, swinlost in settled ticket', N'Checking data of swinlost, mwinlost, swinlost in settled tickete', N'High')

SET @ruleId_s34 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s34, N'EXEC dbo.DBA_Consistency_CheckWinlost3rd @ProductId = 200, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET @taskId_s34 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Checking data of swinlost, mwinlost, swinlost in settled ticket'
 ,@TaskId = @taskId_s34
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-05-24' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Checking data of swinlost, mwinlost, swinlost in settled ticket' AS RuleChecking, @ErrCode, @ErrMsg
