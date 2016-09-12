USE [bodb02]
GO
ALTER PROCEDURE [dbo].[TASK_DepSumData_Job]
	@IdlingHour TINYINT = 9
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Flow controlling for Depopsit Data Summary system 		
		DB: DBACC.bodb02
		Revisions:
		Input Params:	
		- @IdlingHour: 	The point when the system is more idle
	*/
BEGIN
--1.Check server's CPU <= 65%
	DECLARE @ispermit BIT
	EXEC dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT
	IF @ispermit = 0 RETURN
	
	DECLARE @CurrentDate DATE,
			@Yesterday DATE,
			@Earlyday DATE,
			@CurrentHour TINYINT
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @Yesterday = DATEADD(DAY,-1,@CurrentDate)
	SELECT @Earlyday = DATEADD(DAY,-2,@CurrentDate)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
--2.Check system movebet and balanceup
	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isMovingBet','isArchivingBet') AND VValue = '1')
		BEGIN
			PRINT 'TASK_DepSumDataJob: MoveBet/BalanceUp is performing'
			RETURN
		END
--4.Check today's daily archive
		IF NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND StatusID = 1 AND LogType = 2 --Daily Type
					   UNION ALL SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isArchivingDEPdata','isSummaryingDEPdata') AND VValue = '1')
			BEGIN
				EXEC bodb_Report.dbo.TASK_DailyArchiveDepData
				EXEC dbo.Task_DOT_AGCasino_MonthlyReSummary
			END
		ELSE
		BEGIN--3,5,6.Check today's hourly summary at the current's hour
				IF (NOT EXISTS (SELECT 1 FROM bodb_Report.dbo.rptDepWinlost_Log WITH (NOLOCK) WHERE LogDate = @CurrentDate AND LogHour = @CurrentHour AND StatusID = 1 AND LogType BETWEEN 1 AND 3 --Daily/Manually/Hourly Type
					   UNION ALL SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isArchivingDEPdata','isSummaryingDEPdata') AND VValue = '1')
					AND 0 = CASE WHEN @CurrentHour < @IdlingHour THEN 0 ELSE @CurrentHour % 2 END)
				BEGIN
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
					IF NOT EXISTS (SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName IN ('isArchivingDEPdata','isSummaryingDEPdata') AND VValue = '1')
						EXEC dbo.TASK_RealtimeSummaryDepData
				END
		END		
END

