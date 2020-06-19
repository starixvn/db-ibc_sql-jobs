/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Summary]
GO

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra_CheckData_Job]
AS

/*
	Created: 20200618@Malcolm
	Task: Job check data for Sum_Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200618@Malcolm: Initialize SP [RedmineID: #135593]
 
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
		EXEC dbo.Task_DailySum_Winloss_Extra_CheckData @winlostdate = @winlostdate, @isCheckDataOnly = 0, @ProductIds = '46'
			
		SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END
END
GO