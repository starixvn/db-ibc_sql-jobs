/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Summary]
GO

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra_Job]
AS

/*
	Created: 20200618@Malcolm
	Task: Job Gen data for Sum_Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200618@Malcolm: Initialize SP [RedmineID: #135593]
 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME, @MaxWinlostdate DATETIME

	SELECT @MaxWinlostdate = MAX(WinlostDate)
	FROM dbo.Sum_Winloss_Extra WITH (NOLOCK)
	
	SELECT @RowId = 1

	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT 1 FROM @MoveBetSchedule)
		RETURN -- do not move bet on this day


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
				EXEC dbo.Task_DailySum_Winloss_Extra @winlostdate = @WinlostDate, @ProductIds = '46'
				SET @HasError = 0
				BREAK
			END TRY
			BEGIN CATCH
				PRINT 'Failed to generate data for Sum_Winloss_Extra on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' Retry times: ' + CAST(@Retry AS VARCHAR)
				SET @Retry = @Retry + 1
				WAITFOR DELAY '000:00:05.280'
			END CATCH
		END
	END
	
	IF @HasError = 1
	BEGIN
		RAISERROR ('Error occurred during generation of Sum_Winloss_Extra.', 16, 1)
	END
END
