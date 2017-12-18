/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptLicWinlossGMT_CheckData] 
	@WinlostDate SMALLDATETIME
AS
/*
 	Created: 20171130@Sophia
	Task: Check sum for RptLicWinlossGMT vs bettrans14
	DB: DBLIC.bodb_LicenseeReport
	Revisions:  
	- 20171130@Sophia: initial data. Apply for Sportsbook first [redmine: #84932]
	
	EXEC Task_rptLicWinlossGMT_CheckData '2017-11-30'

*/
BEGIN
	SET NOCOUNT ON
	
	EXEC dbo.Task_DailyRptLicWinlossGMT_Bettrans14 @FromDate = @winlostdate
END
GO