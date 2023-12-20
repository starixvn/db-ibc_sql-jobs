/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20231219@July
	Task: Check Data Consistency - Live22 - [Redmine: #198518]
	DB: DBCONSISTENCY-bodb_Consistency

*/

USE bodb_Consistency
GO

DECLARE @ruleId INT, @taskId INT
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT @ruleId = RuleId FROM dbo.DBA_Rules WITH(NOLOCK) WHERE Name LIKE '%Check Stake'

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId, N'EXEC dbo.DBA_Consistency_StakeChecking @ProductId = 227, @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Stake > 0 for dedicated bettypes'
 ,@TaskId = @taskId
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
 --,@Emails ='dba_local@starixsoft.com'
 ,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

 SELECT 'Check Stake >0 for dedicated bettypes - Live22' AS RuleChecking, @ErrCode, @ErrMsg
