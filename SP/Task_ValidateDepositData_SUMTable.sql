USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[Task_ValidateDepositData_SUMTable]    Script Date: 01/19/2015 03:25:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_ValidateDepositData_SUMTable    Script Date: 5/6/2014 09:31:21  ******/


CREATE PROCEDURE [dbo].[Task_ValidateDepositData_SUMTable] 
	@DrawFilter tinyint = 1
AS
/*
Created: 20140505@Francis
Task : Validate data from bettrans14 for SUM Tables

DB: bodb_Licensee
Original:

Revisions:		
-20140506@Francis: Remove datetime param
Param's Explanation:

Examples:


*/
SET NOCOUNT ON

DECLARE @ToDate smalldatetime,
		@tmpDate smalldatetime

DECLARE @Result TABLE (BalanceUpDay smalldatetime, MoveBetsDay smalldatetime)
INSERT INTO @Result
EXEC bodb02.dbo.Lrf_SelBalanceUpDay

SELECT @ToDate = MoveBetsDay
FROM @Result

SELECT @tmpDate = DATEADD(day,-2,@ToDate)

WHILE (@tmpDate <= @ToDate)
BEGIN
		EXEC dbo.Task_DepositDataCompare @Date = @tmpDate, @DrawFilter = @DrawFilter

	SET @tmpDate = DATEADD(day,1,@tmpDate)
END

SET NOCOUNT OFF
GO


