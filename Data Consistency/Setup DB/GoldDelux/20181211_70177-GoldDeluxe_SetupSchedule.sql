/*
	Created: 20181211@Helen
	Task: Setup schedule for GoldDeluxe [Redmine:70177]
	DB: DBTP/bodb_Consistency

*/
USE bodb_Consistency
GO
DELETE [dbo].[DBA_Schedules] WHERE TaskId >= 12
DELETE [dbo].[DBA_JobActivity] WHERE ScheduleId >= 12

--- INSERT DATA
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
--Discount
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Discount value'
 ,@TaskId = 12
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2018-12-11' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com'
 --,@Emails = 'it@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
SELECT 'Discount' RuleChecking, @ErrCode, @ErrMsg
-- PT
GO
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check PT value'
 ,@TaskId = 13
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2018-12-11'  
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com'
 --,@Emails = 'it@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 SELECT 'PT' RuleChecking, @ErrCode, @ErrMsg

--Stake>0
GO
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check Stake >0 for dedicated bettypes'
 ,@TaskId = 14
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2018-12-11' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com'
 --,@Emails = 'it@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 
SELECT 'Stake' RuleChecking, @ErrCode, @ErrMsg
 
 ---All ticket must settled-
 GO
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check all yesterday tickets must be settled'
 ,@TaskId = 15
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2018-12-11' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '01:30'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com'
 --,@Emails = 'it@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT

SELECT 'All ticket must settled' RuleChecking,@ErrCode, @ErrMsg

---Check oddsspread value
GO
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Check oddsspread value'
 ,@TaskId = 16
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2018-12-11' 
 ,@ActiveEndDate = NULL
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com'
 --,@Emails = 'it@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 
 SELECT 'oddsspread' RuleChecking, @ErrCode, @ErrMsg
 
 GO
 

/*
truncate table DBA_Rules
truncate table DBA_Tasks
truncate table DBA_Schedules
*/

