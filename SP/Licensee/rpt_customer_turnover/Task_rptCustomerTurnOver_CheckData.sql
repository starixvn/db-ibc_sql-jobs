
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_rptCustomerTurnOver_CheckData    Script Date: 12/1/2015 2:37:59 AM ******/
/****** Object:  Stored Procedure dbo.Task_rptCustomerTurnOver_CheckData    Script Date: 9/23/2015 10:22:45 AM ******/
CREATE PROCEDURE dbo.Task_rptCustomerTurnOver_CheckData @WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Patrick
	Task : Check & correct data for rptCustomerTurnOver
	DB: DB052.bodb02
	Original:
	Revisions:	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount MONEY, @T_BetCount MONEY
	
	SELECT @S_Winlost = SUM(b.winlost - b.actual_stake)
		, @S_Turnover = SUM(ABS(b.stake))
		, @S_BetCount = COUNT(b.custid)
	FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) lc ON b.recommend = lc.custid	AND b.currency = lc.currency
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111,112,113) --DRAW, WON, LOSE
		--AND b.bettype <= 19999

	SELECT @T_Winlost = SUM(winlost)
		, @T_Turnover = SUM(stake)
		, @T_BetCount = SUM(betcount)
	FROM bodb_licenseereport.dbo.rptCustomerTurnover b WITH(NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) lc ON b.recommend = lc.custid	AND b.currency = lc.currency
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111,112,113,114,115) --DRAW, WON, LOSE
		--AND b.bettype <= 19999

	--select @S_Winlost as '@S_Winlost', @T_Winlost as '@T_Winlost'
	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@S_Turnover, 0) <> ISNULL(@T_Turnover, 0)
		OR ISNULL(@S_BetCount, 0) <> ISNULL(@T_BetCount, 0)
	BEGIN
		PRINT 'Re-generate data for rptCustomerTurnover on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
		EXEC dbo.Task_rptCustomerTurnOver_Bettrans14 @Date = @WinlostDate
		RETURN
	END
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
