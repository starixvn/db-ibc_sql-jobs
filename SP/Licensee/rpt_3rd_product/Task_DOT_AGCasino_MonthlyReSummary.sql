/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0" isNested=”0”></info>*/

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_DOT_AGCasino_MonthlyReSummary    Script Date: 12/1/2015 2:37:57 AM ******/
/****** Object:  Stored Procedure dbo.Task_DOT_AGCasino_MonthlyReSummary    Script Date: 10/1/2015 4:32:32 PM ******/
/****** Object:  Stored Procedure dbo.Task_DOT_AGCasino_MonthlyReSummary    Script Date: 12/10/2014 11:10:40 AM ******/
CREATE PROCEDURE [dbo].[Task_DOT_AGCasino_MonthlyReSummary]	
AS
/*   
Created: 20141209@Winnie
Task: Summary AG Casino data and insert into rptDepWinlost_AGCasino
DB: DBACC/bodb02
Original:
Revisions:	
	- 20151001@Winnie: Add Gold deluxe
	- 20170411@Harper: Include Exchange (separate wallet) to check data [RedmineID: #92485]

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
		
		EXEC DBPTCS.bodb_PlaytechCS.dbo.Task_DOT_GoldDeluxe_DailySummary @winlostdate = @DayOfMonth
		
		-- For Exchange Product
		-- Check data before regen data
		DECLARE @GenBX TINYINT = 0
		EXEC dbo.Task_rptDepWinlost_Exchange_CheckData @WinlostDate = @DayOfMonth, @HasDataMismatch = @GenBX OUTPUT -- Exchange Product

		IF @GenBX <> 0 -- Exchange Product
		BEGIN
			-- Regen data for rptDepWinlost_ThirdParty table
			EXEC bodb_3rdProduct.dbo.Task_DOT_Exchange_DailySummary @winlostdate = @DayOfMonth			
			
			-- Regen data for rpt_BettingByProduct table
			EXEC dbo.GEN_rptBettingByProduct @date = @DayOfMonth, @date2 = @DayOfMonth, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 31 		
		END

		PRINT 'exec'
		print @DayOfMonth
		SET @DayOfMonth=DATEADD(day,1,@DayOfMonth)
	END
	
END TRY
BEGIN CATCH
	-- This SPs called from another SP in rptDepwinlost Summary process, failure of this SP should not affect to that process
	--RAISERROR(15000,1,1,'Error occured in summarizing AG Casino data.')
	PRINT 'Error occured in AGCasino, Gold Deluxe summary data monthly process: ERR_CODE: '+ CAST(ERROR_NUMBER() AS VARCHAR(20)) + ', ERR_MSG: ' + ERROR_MESSAGE()
	RETURN
END CATCH
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
