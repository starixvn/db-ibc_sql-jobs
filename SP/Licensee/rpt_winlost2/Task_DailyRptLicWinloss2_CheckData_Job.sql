/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO
 
ALTER PROCEDURE [dbo].[Task_DailyRptLicWinloss2_CheckData_Job]
AS  
/* 
	Created by: 20150911@Patrick   
	Task: Check & correct data after move bet
	DB: DBLIC.bodb_LicenseeReport
  
	Revision:   
    - 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20161007@Jim: Check & correct data for rpt_BettingColossusBets [RedminID : #63785]
	- 20171130@Sophia: Add step Check & correct data to rptLicWinlossGMT [Redmine: #84932]
	- 20180423@Percy: Remove logic check MB (job handle) [RedmineID: #94129]
*/  
BEGIN  
	SET NOCOUNT ON   
	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME
	
	SELECT @RowId = 1
	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF NOT EXISTS (SELECT TOP 1 1 FROM @MoveBetSchedule)
	BEGIN
		RETURN
	END
	
	-- 20180423@Percy: Remove logic check MB (job handle)
	/*
	SELECT @TotalDayMoveBet = COUNT(1) FROM @MoveBetSchedule
	
	SELECT @TotalDayMoveBetCompleted = COUNT(1)
	FROM DBACC.bodb02.dbo.userlog WITH(NOLOCK)
	WHERE userid = 25520 AND doing = 'Task_DailySummary : End (with Finish)'
		AND logdate > @Today AND logdate < @Tomorrow
	
	IF @TotalDayMoveBet <> @TotalDayMoveBetCompleted
		RETURN --move is processing or move bet does not run
	*/

	DECLARE @ErrorMsg VARCHAR(1000)
	SET @ErrorMsg = ''
	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1

		IF NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE WinlostDate = @WinlostDate)
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
			EXEC dbo.Task_rptBettingParlay_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rptBettingParlay on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH
		
		BEGIN TRY
			EXEC  dbo.Task_rptBettingColossusBets_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH 
			SET @ErrorMsg = @ErrorMsg + 'Failed to check & correct data for rpt_BettingColossusBets on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) 
		END CATCH
		
		BEGIN TRY
			EXEC dbo.Task_rptLicWinlossGMT_CheckData @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @ErrorMsg = 'Failed to check & correct data for rptLicWinlossGMT on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END CATCH
		
	END
	IF ISNULL(@ErrorMsg, '') <> ''
	BEGIN
		RAISERROR (@ErrorMsg, 16, 1)
	END
END
GO