/*<info serverAlias="DBCONSISTENCY-bodb_Consistency"></info>*/
/*
	Created: 20210531@Percy
	DB: DBCONSISTENCY-bodb_Consistency
	Task: LA Setting - Check data consistency - Add rule 3

*/
USE bodb_Consistency
GO

DECLARE @RuleId INT, @TaskId INT

INSERT INTO dbo.DBA_Rules (Name, Description, SeverityLevel)
VALUES ('Launch licensee: compare PT setting in NAP and charge rate in LA', 'Verify if PT setting and LA charge rate consistent', 'Normal')

SELECT @RuleId = SCOPE_IDENTITY()

INSERT INTO dbo.DBA_Tasks (RuleId, command)
VALUES (@RuleId, 'EXEC dbo.DBA_Consistency_LicenseeSettingChecking @RuleId = 3, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT')

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
	,@ActiveStartDate = '2021-06-11' 
	,@ActiveEndDate = NULL
	,@ActiveStartTime = '00:30'
	,@ActiveEndTime = NULL
	,@NotifyLevelEmail = 2
	,@Emails = 'dbaadmin@starixvn.com'
	,@ErrCode  = @ErrCode OUTPUT
	,@ErrMsg = @ErrMsg OUTPUT
SELECT @ErrCode, @ErrMsg
GO