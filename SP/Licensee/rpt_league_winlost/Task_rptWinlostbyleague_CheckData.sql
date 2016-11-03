USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_rptWinlostbyleague_CheckData]
	@WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Sophia
	Task : Check & correct data for rptWinlostbyleague
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
*/

BEGIN 
	SET NOCOUNT ON 

	DECLARE @B_Winlost MONEY, @R_Winlost MONEY
			,@B_Stake MONEY, @R_Stake MONEY
			,@B_Betcount INT, @R_Betcount INT
	
	SELECT @B_Winlost = SUM(b.winlost - b.actual_stake)
			,@B_Stake = SUM (ABS(Stake))
			,@B_Betcount = COUNT (*)
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)		
	INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) LC
		ON b.recommend = lc.custid
			AND b.currency = lc.currency 
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111, 112, 113) -- win lost draw  
 

	SELECT	@R_Winlost = sum(winlost)
			,@R_Stake = SUM (ABS(Stake))
			,@R_Betcount = SUM (Betcount)
	FROM	dbo.rptWinlostbyLeague WITH (NOLOCK)	
	WHERE	winlostdate = @WinlostDate
	 
	 
	IF ISNULL(@B_Winlost, 0) <> ISNULL(@R_Winlost, 0) 
		OR ISNULL(@B_Stake, 0) <> ISNULL(@R_Stake, 0) 
		OR ISNULL(@B_Betcount, 0) <> ISNULL(@R_Betcount, 0)  
	BEGIN 
		PRINT 'Re-generate data for rptWinlostbyleague on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'	

		EXEC dbo.Task_rptWinlostbyleague_Bettrans14 @WinlostDate
	END
END