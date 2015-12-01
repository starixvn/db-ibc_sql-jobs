
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_DailyRptLicIPBetting_Job    Script Date: 12/1/2015 2:37:59 AM ******/
/****** Object:  Stored Procedure dbo.Task_DailyRptLicIPBetting_Job    Script Date: 6/19/2012 11:25:07 AM ******/
CREATE PROCEDURE [dbo].[Task_DailyRptLicIPBetting_Job] 
AS
/*	Created by: Henry 
	Date: 2012-05-30
	Task: Jobs for sum up for rptLicIPBetting
	DB: DB052.bodb02

	Revision: 
		20141226@Daniel: Optimal data gen range to reduce server load
		
		

*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @MaxDateBet14 SMALLDATETIME, @MinDateBet14 SMALLDATETIME, @MaxDate SMALLDATETIME
	
	SELECT @MaxDateBet14 = MAX(winlostdate), @MinDateBet14 = MIN(winlostdate)
	FROM bettrans14 WITH(NOLOCK)
	
	SELECT @MaxDate = MAX(winlostdate) FROM bodb_Licensee.dbo.rptLicIPBetting WITH(NOLOCK)

	IF(@MaxDate < @MinDateBet14 OR @MaxDate IS NULL) SELECT @MaxDate = DATEADD(dd, -1, @MinDateBet14)
				
	WHILE @MaxDate < @MaxDateBet14
	BEGIN	
		SELECT @MaxDate = DATEADD(dd, 1, @MaxDate)
		EXEC [Task_DailyRptLicIPBetting] @winlostdate = @MaxDate
	END
	
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicIPBetting_Job] TO [vnteam]
GO 
