USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_rptDepWinlost_ThirdParty_CheckData]
	@WinlostDate		SMALLDATETIME,
	@ProductID			TINYINT,
	@HasDataMismatch	BIT OUTPUT
AS

/*
	Created: 20170530@Paul
	Task : Check & correct data of rptDepWinlost_ThirdParty
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	IF @ProductID = 10
	BEGIN
		EXEC dbo.Task_rptDepWinlost_ThirdParty_CheckData_AGC @WinlostDate = @WinlostDate, @HasDataMismatch = @HasDataMismatch OUTPUT;
	END

	IF @ProductID = 11
	BEGIN
		EXEC dbo.Task_rptDepWinlost_ThirdParty_CheckData_GD @WinlostDate = @WinlostDate, @HasDataMismatch = @HasDataMismatch OUTPUT;
	END

	SET NOCOUNT OFF;
END