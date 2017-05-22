USE [bodb_LicenseeReport]
GO
/****** Object:  StoredProcedure [dbo].[Task_rptCustomerMatch_CheckData]    Script Date: 09/27/2016 15:27:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_rptCustomerMatch_CheckData    Script Date: 9/27/2016 2:40:13 AM ******/
/****** Object:  Stored Procedure dbo.Task_rptCustomerMatch_CheckData    Script Date: 8/1/2016 09:30:35 ******/
ALTER PROCEDURE [dbo].[Task_rptCustomerMatch_CheckData]
	@WinlostDate SMALLDATETIME
AS
/*
	Created: 20150910@Sophia
	Task : Check & correct data for rptCustomerMatch
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:	
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20170522@Paul: Check awinlost, comm - [Redmine: #76206]
*/

BEGIN 
	SET NOCOUNT ON 

	DECLARE @B_Winlost MONEY, @R_Winlost MONEY
			,@B_Stake MONEY, @R_Stake MONEY
			,@B_Betcount INT, @R_Betcount INT
			,@B_AWinlost MONEY, @R_AWinlost MONEY
			,@B_Comm MONEY, @R_Comm MONEY
	
	SELECT @B_Winlost = SUM(b.winlost - b.actual_stake)
			,@B_Stake = SUM (ABS(Stake))
			,@B_Betcount = COUNT (*)
			,@B_AWinlost = SUM(awinlost)
			,@B_Comm = SUM(comm)
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.f_SelLicenseeCust(0) lc
		ON b.recommend = lc.custid
			AND b.currency = lc.currency
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111, 112, 113)
	

	SELECT	@R_Winlost = sum(winlost)
			,@R_Stake = SUM (ABS(Stake))
			,@R_Betcount = SUM (Betcount)
			,@R_AWinlost = SUM(awinlost)
			,@R_Comm = SUM(comm)
	FROM	dbo.rptCustomerMatch WITH (NOLOCK)	
	WHERE	winlostdate = @WinlostDate
	 

	IF ISNULL(@B_Winlost, 0) <> ISNULL(@R_Winlost, 0) 
		OR ISNULL(@B_Stake, 0) <> ISNULL(@R_Stake, 0) 
		OR ISNULL(@B_Betcount, 0) <> ISNULL(@R_Betcount, 0) 
		OR ISNULL(@B_AWinlost, 0) <> ISNULL(@R_AWinlost, 0)
		OR ISNULL(@B_Comm, 0) <> ISNULL(@R_Comm, 0)
	BEGIN 
		PRINT 'Re-generate data for rptCustomerMatch on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'

		EXEC dbo.Task_rptCustomerMatch_Bettrans14 @Winlostdate
	END 
	
END