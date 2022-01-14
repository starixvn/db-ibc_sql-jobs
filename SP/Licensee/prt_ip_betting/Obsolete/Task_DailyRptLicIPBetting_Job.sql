USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_DailyRptLicIPBetting_Job] 
AS
/*	Created by: Henry 
	Date: 2012-05-30
	Task: Jobs for sum up for rptLicIPBetting
	DB: DBLIC.bodb_LicenseeReport

	Revision: 
		20141226@Daniel: Optimal data gen range to reduce server load
		20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		
		

*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @MaxDateBet14 SMALLDATETIME, @MinDateBet14 SMALLDATETIME, @MaxDate SMALLDATETIME
	
	SELECT @MaxDateBet14 = MAX(winlostdate), @MinDateBet14 = MIN(winlostdate)
	FROM bodb02.dbo.bettrans14 WITH(NOLOCK)
	
	SELECT @MaxDate = MAX(winlostdate) FROM dbo.rptLicIPBetting WITH(NOLOCK)

	IF(@MaxDate < @MinDateBet14 OR @MaxDate IS NULL) SELECT @MaxDate = DATEADD(dd, -1, @MinDateBet14)
				
	WHILE @MaxDate < @MaxDateBet14
	BEGIN	
		SELECT @MaxDate = DATEADD(dd, 1, @MaxDate)
		EXEC dbo.Task_DailyRptLicIPBetting @winlostdate = @MaxDate
	END
	
END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicIPBetting_Job] TO [vnteam] AS [dbo]