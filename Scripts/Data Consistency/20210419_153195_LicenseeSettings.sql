/*<info serverAlias="DBCONSISTENCY-bodb_Consistency"></info>*/
/*
	Created: 20210419@Percy
	DB: DBCONSISTENCY-bodb_Consistency
	Task: LA Setting - Check data consistency

*/
USE bodb_Consistency
GO

DECLARE @RuleId INT, @TaskId INT

INSERT INTO dbo.DBA_Rules (Name, Description, SeverityLevel)
VALUES ('Un-official launch licensee: compare 1st date of the ticket availibity and launch date info', 'Un-official launch licensee: compare 1st date of the ticket availibity and launch date info', 'Normal')

SELECT @RuleId = SCOPE_IDENTITY()

INSERT INTO dbo.DBA_Tasks (RuleId, command)
VALUES (@RuleId, 'EXEC dbo.DBA_Consistency_LicenseeSettingChecking @RuleId = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SELECT @TaskId = SCOPE_IDENTITY()

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
EXEC dbo.DBA_Consistency_ScheduleIns
	@Name = 'LA - Data Consistency Checking'
	,@TaskId = @TaskId
	,@IsEnable  = 1
	,@FrequenceType = 4 -- daily = 4, weekly = 8
	,@FrequenceInterval = 1 -- every xx days
	,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
	,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
	,@ActiveStartDate = '2021-05-11' 
	,@ActiveEndDate = NULL
	,@ActiveStartTime = '00:30'
	,@ActiveEndTime = NULL
	,@NotifyLevelEmail = 2
	,@Emails = 'dbaadmin@starixvn.com'
	,@ErrCode  = @ErrCode OUTPUT
	,@ErrMsg = @ErrMsg OUTPUT
SELECT @ErrCode, @ErrMsg
GO

----------
DECLARE @RuleId INT, @TaskId INT

INSERT INTO dbo.DBA_Rules (Name, Description, SeverityLevel)
VALUES ('Launch licensee: compare 1st date of the ticket availibity of a product and product charge rate setting', 'Launch licensee: compare 1st date of the ticket availibity of a product and product charge rate setting', 'Normal')

SELECT @RuleId = SCOPE_IDENTITY()

INSERT INTO dbo.DBA_Tasks (RuleId, command)
VALUES (@RuleId, 'EXEC dbo.DBA_Consistency_LicenseeSettingChecking @RuleId = 2, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

SELECT @TaskId = SCOPE_IDENTITY()

DECLARE @ErrCode INT, @ErrMsg VARCHAR(100)
EXEC dbo.DBA_Consistency_ScheduleIns
	@Name = 'LA - Data Consistency Checking'
	,@TaskId = @TaskId
	,@IsEnable  = 1
	,@FrequenceType = 4 -- daily = 4, weekly = 8
	,@FrequenceInterval = 1 -- every xx days
	,@FrequenceSubDayType = 1 -- specified time: 1, second: 2, min: 4, hour: 8
	,@FrequenceSubDayInterval = 0 -- specified time: 0; <> 0: every FrequenceSubDayType
	,@ActiveStartDate = '2021-05-11' 
	,@ActiveEndDate = NULL
	,@ActiveStartTime  = '00:30'
	,@ActiveEndTime = NULL
	,@NotifyLevelEmail = 2
	,@Emails = 'dbaadmin@starixvn.com'
	,@ErrCode  = @ErrCode OUTPUT
	,@ErrMsg = @ErrMsg OUTPUT
SELECT @ErrCode, @ErrMsg