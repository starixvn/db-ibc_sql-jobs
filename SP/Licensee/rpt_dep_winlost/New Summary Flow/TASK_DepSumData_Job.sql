/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job]
	@IdlingHour TINYINT = 9
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Flow controlling for Depopsit Data Summary system 		
		DB: DBACC.bodb02
		Revisions:
			20170728@Patrick: Remove code check HighCPU
			20180618@Sophia: Change the flag of Movebet and Balanceup  [redmine: #97071]
		
		Input Params:	
		- @IdlingHour: The time when the system is more idle
	*/
BEGIN
--1.Check server's CPU <= 65%
	--DECLARE @ispermit BIT
	--EXEC dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT
	--IF @ispermit = 0 RETURN
	
	DECLARE @CurrentDate DATE,
			@Yesterday DATE,
			@Earlyday DATE,
			@CurrentHour TINYINT
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @Yesterday = DATEADD(DAY,-1,@CurrentDate)
	SELECT @Earlyday = DATEADD(DAY,-2,@CurrentDate)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
--2.Check system movebet and balanceup
	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isMovingBet_Local','isArchivingBet_Local','isArchivingDEPdata','isSummaryingDEPdata') AND VValue <> '0')
		BEGIN
			PRINT 'EXEC TASK_DepSumDataJob: MoveBet/BalanceUp/ArchivingDEPdata/SummaryingDEPdata is performing ==> RETURN'
			RETURN
		END
--4.Check today's daily archive
		IF NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND StatusID = 1 AND LogType = 2) --Daily Type
			BEGIN
				--PRINT 'EXEC TASK_DailyArchiveDepData'
				EXEC bodb_Report.dbo.TASK_DailyArchiveDepData
				EXEC dbo.Task_DOT_AGCasino_MonthlyReSummary
			END
		ELSE
		BEGIN--3,5,6.Check today's hourly summary at the current's hour
				IF (NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND LogHour = @CurrentHour AND StatusID = 1 AND LogType BETWEEN 1 AND 3) --Daily/Manually/Hourly Type
					AND 0 = CASE WHEN @CurrentHour < @IdlingHour THEN 0 ELSE @CurrentHour % 2 END)
				BEGIN
					--PRINT 'EXEC TASK_HourlySummaryDepData'
					--
					EXEC dbo.Task_rptWinLost_UpdateTable @winlostdate = @CurrentDate
					EXEC dbo.Task_rptWinLost_UpdateTable @winlostdate = @Yesterday
					EXEC dbo.Task_rptWinLost_UpdateTable @winlostdate = @Earlyday
					--
					EXEC dbo.Task_Aff_MemberDailySummary_IA @winlostdate = @CurrentDate
					EXEC dbo.Task_Aff_MemberDailySummary_IA @winlostdate = @Yesterday
					EXEC dbo.Task_Aff_MemberDailySummary_IA @winlostdate = @Earlyday
					--
					EXEC bodb_Report.dbo.TASK_HourlySummaryDepData
				END
				ELSE
				BEGIN
					--PRINT 'EXEC TASK_RealtimeSummaryDepData'
					EXEC dbo.TASK_RealtimeSummaryDepData @Winlostdate = @Yesterday
					EXEC dbo.TASK_RealtimeSummaryDepData
				END
		END		
END
GO