/*<info serverAlias="DBACC-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job]
	@IdlingHour TINYINT = 9
AS

/*
	Created: 20160815@Francis
	DB: DBACC.bodb02
	Task: Flow controlling for Depopsit Data Summary system
		
	Revisions:
		- 20170728@Patrick: Remove code check HighCPU
		- 20180618@Sophia: Change the flag of Movebet and Balanceup  [redmine: #97071]
		- 20200417@Percy: Remove code gen data for MemberDailyIA [RedmineID: #132740]
		- 20220422@Sol: LAP - Enhance database jobs - [RedmineID: #171747]
		- 20230227@Evan: Balance-Up support transfer 247 [RedmineID: #173554]

		
	Input Params:	
	- @IdlingHour: The time when the system is more idle
*/

BEGIN
	DECLARE @CurrentDate	DATE,
			@Yesterday		DATE,
			@Earlyday		DATE,
			@CurrentHour	TINYINT

	SELECT  @CurrentDate	= CONVERT(DATE, CURRENT_TIMESTAMP, 112)
	SELECT  @Yesterday		= DATEADD(DAY, -1, @CurrentDate)
	SELECT  @Earlyday		= DATEADD(DAY, -2, @CurrentDate)
	SELECT  @CurrentHour	= DATEPART(HOUR, CURRENT_TIMESTAMP)

	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isArchivingDEPdata','isSummaryingDEPdata') AND VValue <> '0')
	BEGIN
		PRINT 'EXEC TASK_DepSumDataJob: ArchivingDEPdata/SummaryingDEPdata is performing ==> RETURN'
		RETURN
	END

	-- Check today's daily archive
	IF NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND StatusID = 1 AND LogType = 2) -- Daily Type
	BEGIN
		EXEC bodb_Report.dbo.TASK_DailyArchiveDepData
		EXEC dbo.Task_DOT_AGCasino_MonthlyReSummary
	END
	ELSE
	BEGIN
		-- Check today's hourly summary at the current's hour
		IF (NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND LogHour = @CurrentHour AND StatusID = 1 AND LogType BETWEEN 1 AND 3) --Daily/Manually/Hourly Type
					AND 0 = CASE WHEN @CurrentHour < @IdlingHour THEN 0 ELSE @CurrentHour % 2 END)
		BEGIN
			EXEC bodb_Report.dbo.TASK_HourlySummaryDepData
		END
		ELSE -- run realtime
		BEGIN
			EXEC dbo.TASK_RealtimeSummaryDepData @Winlostdate = @Yesterday
			EXEC dbo.TASK_RealtimeSummaryDepData
		END
	END		
END
GO