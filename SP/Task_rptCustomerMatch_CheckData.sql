
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_rptCustomerMatch_CheckData    Script Date: 9/15/2015 4:14:02 PM ******/
CREATE PROCEDURE [dbo].[Task_rptCustomerMatch_CheckData]
	@WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Sophia
	Task : Check & correct data for rptCustomerMatch
	DB: DBEXT/bodb02
	Original:
	Revisions:	
*/

BEGIN 
	SET NOCOUNT ON 

	DECLARE @B_Winlost MONEY, @R_Winlost MONEY
			,@B_Stake MONEY, @R_Stake MONEY
			,@B_Betcount INT, @R_Betcount INT
	
	SELECT @B_Winlost = SUM(b.winlost - b.actual_stake)
			,@B_Stake = SUM (ABS(Stake))
			,@B_Betcount = COUNT (*)
	FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) lc
		ON b.recommend = lc.custid
			AND b.currency = lc.currency
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111, 112, 113)
	

	SELECT	@R_Winlost = sum(winlost)
			,@R_Stake = SUM (ABS(Stake))
			,@R_Betcount = SUM (Betcount)
	FROM	bodb_LicenseeReport.dbo.rptCustomerMatch WITH (NOLOCK)	
	WHERE	winlostdate = @WinlostDate
	 

	IF ISNULL(@B_Winlost, 0) <> ISNULL(@R_Winlost, 0) 
		OR ISNULL(@B_Stake, 0) <> ISNULL(@R_Stake, 0) 
		OR ISNULL(@B_Betcount, 0) <> ISNULL(@R_Betcount, 0) 
	BEGIN 
		PRINT 'Re-generate data for rptCustomerMatch on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'

		EXEC dbo.Task_rptCustomerMatch_Bettrans14 @Winlostdate
	END 
	
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
