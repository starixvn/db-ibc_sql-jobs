/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210712@July
	Task: Detect Netstake <> 0 for RNG products [Redmine:#158179]
	DB: DBCONSISTENCY-bodb_Consistency

*/
USE bodb_Consistency
GO

DECLARE	@ruleId_s36 INT, @taskId_s36 INT

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

--S36 - Add rules for RNG products
INSERT [dbo].[DBA_Rules] ([Name], [Description], [SeverityLevel]) 
VALUES (N'Detect Netstake <> 0 for RNG products', N'Detect Netstake <> 0 for RNG products', N'High')

SET @ruleId_s36 = SCOPE_IDENTITY()

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId_s36, N'EXEC dbo.DBA_Consistency_DetectNetstakeforRNGChecking @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SET @taskId_s36 = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Detect Netstake <> 0 for RNG products'
 ,@TaskId = @taskId_s36
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2021-07-20' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:15'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 --,@Emails = 'dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Detect Netstake <> 0 for RNG products' AS RuleChecking, @ErrCode, @ErrMsg