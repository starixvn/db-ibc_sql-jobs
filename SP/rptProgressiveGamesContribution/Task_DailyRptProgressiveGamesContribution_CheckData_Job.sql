/*<info serverAlias="DBSUM-bodb_Summary" executers="vnteam" viewers="" isFunction="0" isNested="0"></info>*/
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
 
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
		
	DECLARE @winlostdate SMALLDATETIME, @MoveBetsDay SMALLDATETIME, @BalanceUpDay SMALLDATETIME
		
	SELECT @MoveBetsDay = MAX(eventdate)
	FROM bodb02.dbo.match14 WITH(NOLOCK)
		
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
		
	SELECT @winlostdate = @BalanceUpDay
		
	WHILE(@winlostdate <= @MoveBetsDay)
	BEGIN
		EXEC dbo.Task_DailyRptProgressiveGamesContribution_CheckData @winlostdate = @winlostdate, @isCheckDataOnly = 0
			
		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END
END
GO