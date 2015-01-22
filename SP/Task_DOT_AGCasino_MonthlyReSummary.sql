USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DOT_AGCasino_MonthlyReSummary]    Script Date: 01/22/2015 00:09:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_DOT_AGCasino_MonthlyReSummary    Script Date: 12/10/2014 11:10:40 AM ******/
CREATE PROCEDURE [dbo].[Task_DOT_AGCasino_MonthlyReSummary]	
AS
/*   
Created: 20141209@Winnie
Task: Summary AG Casino data and insert into rptDepWinlost_AGCasino
DB: DBACC/bodb02
Original:
Revisions:	
Param's Explanation:
*/ 
BEGIN 
SET NOCOUNT ON

IF((SELECT DAY(getdate()))<>3)
RETURN
BEGIN TRY
	DECLARE @DayOfMonth DATETIME
	SELECT @DayOfMonth=DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0) --as FirtDayPreviousMonthWithTimeStamp
		
	WHILE(@DayOfMonth<getdate())
	BEGIN
	EXEC dbo.Task_DOT_AGCasino_DailySummary @winlostdate = @DayOfMonth
	print 'exec'
	print @DayOfMonth
	SET @DayOfMonth=DATEADD(day,1,@DayOfMonth)
	END
	
END TRY
BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	--RAISERROR(15000,1,1,'Error occured in summarizing AG Casino data.')
	PRINT 'Error occured in AGCasino summary data process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH
END
GO


