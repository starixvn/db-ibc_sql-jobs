/*<info serverAlias="DBACC-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DOT_AGCasino_MonthlyReSummary]	
AS
/*   
	Created: 20141209@Winnie
	Task: Summary AG Casino data and insert into rptDepWinlost_AGCasino
	DB: DBACC/bodb02
	Original:

	Revisions:	
		- 20151001@Winnie: Add Gold deluxe
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 2022831@Sol: Deposit - AWS - Modify jobs of separated wallet - Move table rptDepWinlost_AGCasino to DB05x - [RedmineID: #176479]

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
	
		EXEC DBPTCS.bodb_PlaytechCS.dbo.Task_DOT_GoldDeluxe_DailySummary @winlostdate = @DayOfMonth
		print 'exec'
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