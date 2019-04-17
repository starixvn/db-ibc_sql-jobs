/*
	Created: Helen
	Task: insert task for AllBet & OneRnG Bettype
	DB: DBTP/bodb_Consistency
	Date: 20190416
*/
USE [bodb_Consistency]
GO

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Allbet - Win 3 Cards - Check un-launched sites Batch 1'
 ,@TaskId = 39
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2019-04-17'
 ,@ActiveEndDate = '2019-04-24'
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com;gary.vu@starixsoft.com'
 --,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 
SELECT 'Allbet - Win 3 Cards - Check un-launched sites Batch 1' RuleChecking, @ErrCode, @ErrMsg

go
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'Allbet - Win 3 Cards - Check un-launched sites Batch 2'
 ,@TaskId = 40
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2019-04-25'
 ,@ActiveEndDate = '2019-05-01'
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com;gary.vu@starixsoft.com'
 --,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 
SELECT 'Allbet - Win 3 Cards - Check un-launched sites Batch 2' RuleChecking, @ErrCode, @ErrMsg

go
DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)

EXEC dbo.DBA_Consistency_ScheduleIns @Name = 'OneRNG - Mini Dice new game - Batch 1'
 ,@TaskId = 41
 ,@IsEnable  = 1
 ,@FrequenceType = 4 -- daily = 4, weekly = 8
 ,@FrequenceInterval = 1 -- every xx days
 ,@FrequenceSubDayType = 8 -- specified time: 1, second: 2, min: 4, hour: 8
 ,@FrequenceSubDayInterval = 1 -- specified time: 0; <> 0: every FrequenceSubDayType
 ,@ActiveStartDate = '2019-04-16'
 ,@ActiveEndDate = '2019-04-23'
 ,@ActiveStartTime  = '00:00'
 ,@ActiveEndTime = NULL
 ,@NotifyLevelEmail = 2
 ,@Emails = 'helen.do@starixsoft.com;gary.vu@starixsoft.com'
 --,@Emails = 'dbaadmin@starixsoft.com'
 ,@ErrCode  = @ErrCode OUTPUT
 ,@ErrMsg = @ErrMsg OUTPUT
 
SELECT 'OneRNG - Mini Dice new game - Batch 1' RuleChecking, @ErrCode, @ErrMsg

DECLARE @activeStartDate VARCHAR(20), @email VARCHAR(MAX)