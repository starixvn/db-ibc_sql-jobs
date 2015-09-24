USE bodb02
GO
  
ALTER PROCEDURE dbo.Task_DailyRptLicWinloss2_CheckData_Job
AS  
/* 
	Created by: 20150911@Patrick   
	Task: Check & correct data after move bet
	DB: DB052.bodb02  
  
	Revision:   
  
*/  
BEGIN  
	SET NOCOUNT ON   
	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME, @TotalDayMoveBet TINYINT
		, @TotalDayMoveBetCompleted TINYINT, @Tomorrow DATETIME, @Today DATETIME
	
	SELECT @RowId = 1, @Tomorrow = DATEADD(dd, 1, CAST(GETDATE() AS DATE)), @Today = DATEADD(dd, -1, CAST(GETDATE() AS DATE))

	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	SELECT @TotalDayMoveBet = COUNT(1) FROM @MoveBetSchedule

	SELECT @TotalDayMoveBetCompleted = COUNT(1)
	FROM DBACC.bodb02.dbo.userlog WITH(NOLOCK)
	WHERE userid = 25520 AND doing = 'Task_DailySummary : End (with Finish)'
		AND logdate > @Today AND logdate < @Tomorrow
	
	IF @TotalDayMoveBet <> @TotalDayMoveBetCompleted
		RETURN --move is processing or move bet does not run

	DECLARE @ErrorMsg VARCHAR(1000)
	SET @ErrorMsg = ''
	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1

		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.bettrans14 WITH(NOLOCK) WHERE WinlostDate = @WinlostDate)
			CONTINUE --does not exist data in bettrans 14

		PRINT 'WinlostDate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112)

		BEGIN TRY
			EXEC dbo.Task_rptLicWinloss2_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @ErrorMsg = 'Failed to check & correct data for rptLicWinloss2 on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END CATCH

		BEGIN TRY
			EXEC dbo.Task_rptCustomerTurnOver_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rptCustomerTurnOver on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH
		
		BEGIN TRY
			EXEC dbo.Task_rptWinlostbyleague_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rptWinlostbyleague on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH
		
		BEGIN TRY
			EXEC dbo.Task_rptCustomerMatch_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rptCustomerMatch on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH

		BEGIN TRY
			EXEC bodb_Licensee.dbo.Task_rptBettingParlay_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rptBettingParlay on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH
		
	END
	IF ISNULL(@ErrorMsg, '') <> ''
	BEGIN
		RAISERROR (@ErrorMsg, 16, 1)
	END
END

GO
