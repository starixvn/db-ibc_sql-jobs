USE [bodb02]
GO
ALTER PROCEDURE [dbo].[GEN_HourlySummaryDepData_Bettrans14]
	@Winlostdate SMALLDATETIME,
	@NumberofCus INT = 0 OUTPUT,
	@isSuccessful BIT = 0 OUTPUT
AS
	/*
		Created By: Francis
		Created Date: 20160816
		Task: Generate data for Deposit Data summary system for one winlostdate from bettrans14 		
		DB: DBACC.bodb02
		Revisions:
		Input Params:	
		- @Winlostdate: The input Winlostdate to be summarized
		- @NumberofCus: The number of customer have been summarized
		- @isSuccessful: -1: Data of the whole day has been summarized completely
						 -0: Data of the whole day has not been summarized completely
	*/
BEGIN
	RETURN
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bettrans WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
		BEGIN
			BEGIN TRY
				IF EXISTS (SELECT TOP 1 1 FROM bodb_Report.dbo.rptDepWinlost_Trans WITH (NOLOCK) WHERE Winlostdate = @Winlostdate)
					BEGIN
						PRINT 'GEN FROM bettrans14'
					END
				ELSE
					BEGIN
						PRINT 'GEN FROM bettrans14'
					END
			END TRY
			BEGIN CATCH
				SET @isSuccessful = 0
				PRINT 'ERROR'
			END CATCH
		END
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @Winlostdate AND bettype < 19999 AND bettype != 18000)
		BEGIN
			BEGIN TRY
				PRINT 'GEN FROM bettrans14'
			END TRY
			BEGIN CATCH
				SET @isSuccessful = 0
				PRINT 'ERROR'
			END CATCH
		END
END

