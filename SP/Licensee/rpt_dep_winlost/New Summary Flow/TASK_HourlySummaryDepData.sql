USE [bodb_Report]
GO
ALTER PROCEDURE [dbo].[TASK_HourlySummaryDepData]
	@isDailyArc bit = 0,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Hourly Summary for Depopsit Data summary system every each 1 or 2 hours
		DB: DBRPT.bodb_Report
		Revisions:
		Input Params:	
		@isManual: -0: Summarize data for 2 days: today and yesterday
				   -1: Summarize data from the minimum (winlostdate which has not been regenerated) in table rptDepWinlost_Manual til the day before yesterday
	*/
BEGIN
	DECLARE @CurrentDate DATE,
			@CurrentHour TINYINT,
			@LogDesc VARCHAR(8000) = 'Date generated: ',
			@MinDate DATE = NULL,
			@MaxDate DATE,
			@MaxSumDate DATE,
			@MinManualDate SMALLDATETIME,
			@isManual BIT = 0,
			@LogID BIGINT,
			@NumberofCus INT= 0,
			@ErrMsg VARCHAR(MAX) = '',
			@TempDay DATE = NULL,
			@TotalSuccessfulDay TINYINT = 0,
			@MoveBetDay SMALLDATETIME,
			@BalanceUpDay SMALLDATETIME
			
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0 and custid = 3
	
	SELECT @MoveBetDay = MAX(eventdate)
	FROM dbo.match14 WITH(NOLOCK)
	
	--Check if is there any day need to be manually resummarized
	IF EXISTS (SELECT TOP 1 1 FROM dbo.rptDepWinlost_Manual WITH (NOLOCK) WHERE IsSummarized = 0)
		SELECT @isManual = 1, @MinManualDate = MIN(winlostdate) 
		FROM dbo.rptDepWinlost_Manual WITH (NOLOCK) 
		WHERE IsSummarized = 0
		
	--4.Set date range due to @isDailyArc	
	SELECT @MaxDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @MinDate = DATEADD(DAY,-2,@MaxDate)

	IF @isDailyArc = 1 AND @MoveBetDay < @MinDate
		SELECT @MinDate = @MoveBetDay
	IF @isManual = 1 AND @MinManualDate < @MinDate
		SELECT @MinDate = @MinManualDate
		
	--1.Check if there is any day to summarize or not
	IF @MinDate < @BalanceUpDay OR @MinDate > @MaxDate
		RETURN
	
	SELECT @TempDay = @MinDate, @MaxSumDate = CONVERT(DATE,DATEADD(DAY,-6,CURRENT_TIMESTAMP),112)

	--2.Insert Log
	INSERT INTO dbo.rptDepWinlost_Log(Logdate, LogHour, LogType, StartTime)
		SELECT @CurrentDate, @CurrentHour, 
				CASE WHEN @isManual = 1
				THEN 1 --LogType: Manual
				ELSE 3 --LogType: Hourly
				END
				, CURRENT_TIMESTAMP AS StartTime		
	SELECT @LogID = @@IDENTITY
	

	--3.Update SystemSettings
	UPDATE bodb02.dbo.SystemSettings WITH (ROWLOCK, UPDLOCK) 
	SET VValue = '1'
	WHERE VName = 'isSummaryingDEPdata'
	
	WHILE @TempDay <= @MaxDate
	BEGIN
		--5.Summarize data 
		IF @TempDay > @MoveBetDay
		EXEC bodb02.dbo.GEN_HourlySummaryDepData @Winlostdate = @TempDay, @NumberofCus = @NumberofCus OUTPUT
												 , @isSuccessful = @isSuccessful OUTPUT
		ELSE
		EXEC bodb02.dbo.GEN_HourlySummaryDepData_Bettrans14 @Winlostdate = @TempDay, @NumberofCus = @NumberofCus OUTPUT
												 , @isSuccessful = @isSuccessful OUTPUT
												 
		SELECT @LogDesc = @LogDesc + CONVERT(VARCHAR(20),@TempDay) + ' (No. of Customer affected: ' + CONVERT(VARCHAR(20), @NumberofCus) + 
				CASE WHEN @TempDay < @MaxDate THEN '), ' ELSE ')' END
				, @TotalSuccessfulDay = @TotalSuccessfulDay + @isSuccessful
		
		--If there is any day unsuccessfully summarized, break the chain
		IF @isSuccessful = 0 BREAK
		
		IF @TempDay <= @MaxSumDate AND @isDailyArc = 0
			EXEC dbo.Task_DepWinlostSUM @date = @TempDay 
		
		IF @isManual = 0
		BEGIN
			-- Execute SP to insert data for Playtech Casino
			EXEC bodb02.dbo.Task_DOT_PlaytechCS_DailySummary @winlostdate = @TempDay
			-- Execute SP to insert data for AG Casino
			EXEC bodb02.dbo.Task_DOT_AGCasino_DailySummary @winlostdate = @TempDay
		END
		
		SELECT @TempDay = DATEADD(DAY,1,@TempDay)
	END
	
	--6.Update SystemSettings
	UPDATE bodb02.dbo.SystemSettings WITH (ROWLOCK, UPDLOCK) 
	SET VValue = '0'
	WHERE VName = 'isSummaryingDEPdata'
	
	--9.Update Log
	--SELECT @LogDesc = LEFT(@LogDesc,LEN(@LogDesc)-1)
	SELECT @LogDesc = @LogDesc + ';'
	IF @isManual = 1
		SELECT @LogDesc = @LogDesc + ' Type: manually'
	ELSE
		SELECT @LogDesc = @LogDesc + ' Type: hourly'
	
	--7.Check if all days have been summarized successfully
	IF @TotalSuccessfulDay = DATEDIFF(DAY,@MinDate,@MaxDate)
	BEGIN
		SET @isSuccessful = 1
		IF @isManual = 1
			--8.Update IsSummarized for days that have been regenerated in rpt_Depwinlost_Manual
			UPDATE dbo.rptDepWinlost_Manual WITH (ROWLOCK, UPDLOCK) 
			SET IsSummarized = 1
			WHERE Winlostdate >= @MinDate AND IsSummarized = 0
	
		--8.Update Log
		UPDATE dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID
	END
	ELSE
	BEGIN
		SET @isSuccessful = 0
		--9.Update Log
		UPDATE dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
		SET EndTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
		WHERE LogID = @LogID
	END
END

