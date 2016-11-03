USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[Task_ValidateDepositData_SUMTable] 
	@DrawFilter tinyint = 1
AS
/*
Created: 20140505@Francis
Task : Validate data from bettrans14 for SUM Tables

DB: bodb_LicenseeReport
Original:

Revisions:		
-20140506@Francis: Remove datetime param
-20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
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