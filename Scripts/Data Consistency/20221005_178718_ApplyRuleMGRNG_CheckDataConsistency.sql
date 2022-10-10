/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20221005@July
	Task: Data Consistency - Add task/schedule for other product - Rule Wrong discount or comm value  [Redmine:#178718]
	DB: DBCONSISTENCY-bodb_Consistency
	Add Product: MG-RNG (155)
*/

USE bodb_Consistency
GO
DECLARE @ruleId INT, @taskId INT
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)

SELECT @ruleId = RuleId FROM dbo.DBA_Rules WITH(NOLOCK) WHERE Name LIKE '%Wrong discount or comm value%'

INSERT [dbo].[DBA_Tasks] ([RuleId], [command]) 
VALUES (@ruleId, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 155, @Rule = ''no_discount_comm'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
SET @taskId = SCOPE_IDENTITY()

--------- SCHEDULE ---------------
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Wrong discount or comm value'
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
 --,@Emails ='dba_local@starixvn.com'
 ,@Emails = 'dbaadmin@starixvn.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'Wrong discount or comm value' AS RuleChecking, @ErrCode, @ErrMsg
