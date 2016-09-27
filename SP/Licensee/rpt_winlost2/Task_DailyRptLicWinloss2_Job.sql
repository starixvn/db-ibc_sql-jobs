USE [bodb_LicenseeReport]
GO 
ALTER PROCEDURE [dbo].[Task_DailyRptLicWinloss2_Job]
AS  
/* Created by: Henry   
 Date: 2011-09-20  
 Task: Jobs for sum up date for rptLicWinlost  
 DB: DBLIC.bodb_LicenseeReport
  
 Revision:   
  - 20140108@Don: Add step to generate data to [bodb_LicenseeReport.rptCustomerTurnover]  
  - 20140117@Don: Add step to generate data to [bodb_LicenseeReport.rptWinlostbyleague]  
  - 20140725@Don: Add step to generate data to [bodb_LicenseeReport.rpt_BettingParlay]  
  - 20150909@Patrick: Changes the way generate data from bettrans instead bettrans14
  - 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
  - 20161003@Jim: Add step to generate data to [bodb_LicenseeReport.rpt_BettingColossusBets]  [RedminID : #63785]
  
*/  
BEGIN  
	SET NOCOUNT ON   
	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME, @MaxLicWinlostdate DATETIME

	SELECT @MaxLicWinlostdate = MAX(WinlostDate)
	FROM dbo.rptLicWinloss2 WITH (NOLOCK)
	
	SELECT @RowId = 1

	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT 1 FROM @MoveBetSchedule)
		RETURN --do not move bet on this day
	
	IF EXISTS (SELECT TOP 1 1 FROM @MoveBetSchedule WHERE MoveBetDay = @MaxLicWinlostdate) --already generate data on that day
		RETURN

	DECLARE @Retry TINYINT = 1, @MaxRetry TINYINT = 3, @HasError BIT
	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1
		
		PRINT 'WinlostDate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112)

		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_DailyRptLicWinloss2_Bettrans @winlostdate = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for RptLicWinloss2 on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_rptCustomerTurnOver_Bettrans @Date = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for rptCustomerTurnOver on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END
     
		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_rptWinlostbyleague_Bettrans @Date = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for rptWinlostbyleague on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_rptCustomerMatch_Bettrans @Date = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for rptCustomerMatch on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END

		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
				EXEC dbo.GEN_rptBetting_Parlay @date = @WinlostDate, @date2 = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for rptBetting_Parlay on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END
		
		SELECT @Retry = 1, @HasError = 1
		WHILE @Retry <= @MaxRetry
		BEGIN
			BEGIN TRY
								EXEC bodb_Licensee.dbo.GEN_rptBetting_ColossusBets @date = @WinlostDate, @date2 = @WinlostDate
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for GEN_rptBetting_ColossusBets on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END
		
	END

	IF @HasError = 1
	BEGIN
		RAISERROR ('Error occurred during generation of Licensee Winloss.', 16, 1)
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicWinloss2_Job] TO [vnteam] AS [dbo]