USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DailyRptLicWinloss_Job]    Script Date: 01/19/2015 06:33:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_DailyRptLicWinloss_Job] 
AS
/*	Created by: Henry 
	Date: 2011-04-21
	Task: Jobs for sum up date for rptLicWinloss
	DB: DB052.bodb02

	Revision: 
		-20110516@Jamie: Modify the condition in calling jobs
		

*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @maxLicWinlostdate DATETIME, 
			@maxSumWinlostdate DATETIME

	SELECT  @maxLicWinlostdate=Max(Winlostdate) + 1 
	FROM	bodb_Licensee.dbo.rptLicWinloss WITH (NOLOCK)

	
	SELECT	@maxSumWinlostdate = MAX(winlostdate)
	FROM	Sum_winloss WITH (NOLOCK)
	WHERE	Srecommend = 791080 and roleid = 4

	IF(@maxLicWinlostdate <= @maxSumWinlostdate)
	BEGIN
		WHILE (@maxLicWinlostdate<= @maxSumWinlostdate)
		BEGIN
			PRINT @maxLicWinlostdate
			EXEC dbo.Task_DailyRptLicWinloss @winlostdate = @maxLicWinlostdate
			SET @maxLicWinlostdate = @maxLicWinlostdate + 1 
		END		

	END
	
	
END  
	


GO

GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptLicWinloss_Job] TO [vnteam] AS [dbo]
GO


