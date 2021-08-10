/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Summary]
GO

ALTER PROCEDURE [dbo].[Task_DailyRptProgressiveGamesContribution_CheckData_Job]
AS

/*
	Created: 20180222@Percy
	Task: Job check data for rptProgressiveGamesContribution [Redmine: #83787]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20180222@Percy: Initialize SP [RedmineID: #83787]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
		
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	-- get move bet date
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp
		
	SELECT @winlostdate = @BalanceUpDay
		
	WHILE(@winlostdate <= @MoveBetsDay)
	BEGIN
		EXEC dbo.Task_DailyRptProgressiveGamesContribution_CheckData @winlostdate = @winlostdate, @isCheckDataOnly = 0
			
		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END
END
GO