USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_RMS_DailySummaryWinloss_Job]    Script Date: 01/19/2015 04:37:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_RMS_DailySummaryWinloss_Job    Script Date: 9/18/2013 2:07:17 PM ******/
ALTER PROCEDURE [dbo].[Task_RMS_DailySummaryWinloss_Job]
AS
	/*
		Created: Johnson
		Date: 2012-11-07
		Task: Summary winloss RMS
		DB: DBRMS/bodb_RMS
		
		Revisions:
			- 20130301@Jamie: standardize the ErrMsg
			- 20130814@Johnson: check data on rmSumWinloss2
			- 20130918@Johnson: change to use table rmSumWinloss instead of rmSumWinloss2
			- 20160510@Winnie: Change for combo parlay
		Parameter's Explanation: 
	*/
SET NOCOUNT ON
	DECLARE @MaxWinlostDate_Sum DATETIME,
			@MaxWinlostDate_RM DATETIME, @ErrCode INT, @ErrMsg NVARCHAR(4000)
	
	SELECT @MaxWinlostDate_Sum = MAX(winlostdate)
	FROM bodb02.dbo.sum_winloss WITH(NOLOCK)
	
	SELECT @MaxWinlostDate_RM = MAX(winlostdate) + 1
	FROM rmSumWinloss WITH(NOLOCK)

	IF @MaxWinlostDate_RM IS NULL
		SELECT @MaxWinlostDate_RM = MIN(winlostdate)
		FROM bodb02.dbo.bettrans14 WITH(NOLOCK)
	
	WHILE (@MaxWinlostDate_RM <= @MaxWinlostDate_Sum)
	BEGIN
		
		EXEC [dbo].[Task_RMS_DailySummaryWinloss] @winlostdate = @MaxWinlostDate_RM, @ErrCode = @ErrCode OUTPUT ,@ErrMsg=@ErrMsg OUTPUT
		
		IF @ErrCode > 0 AND @MaxWinlostDate_RM=@MaxWinlostDate_Sum
		BEGIN
			RAISERROR(@ErrMsg,16,1)
			RETURN
		END
			
		SELECT @MaxWinlostDate_RM = @MaxWinlostDate_RM + 1 			
	END
GO


