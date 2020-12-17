/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/

/*
	Created: 20201214@Kos
	Task: Generate data of SAG for 2020-06-12 -> 2020-10-08 [RedmineID: #147062]
	DB: DBLIC-bodb_LicenseeReport
	Remark: Re-gen data for SA Gaming
*/

USE bodb_LicenseeReport
GO

DECLARE
	@StartDate		DATE = '2020-06-12 00:00:00',
	@EndDate		DATE = '2020-10-08 00:00:00',
	@TempEndDate	DATE

WHILE @StartDate <= @EndDate
BEGIN
	SET @TempEndDate = CASE
							WHEN DATEADD(DAY, 5, @StartDate) > @EndDate THEN @EndDate
							ELSE DATEADD(DAY, 5, @StartDate)
						END

	PRINT 'Regen data rptBettingByProduct from ' + CONVERT(VARCHAR, @StartDate, 101) + ' to ' + CONVERT(VARCHAR, @TempEndDate, 101)

	EXEC GEN_rptBettingByProduct @date = @StartDate, @date2 = @TempEndDate, @DataSource = 'Rpt_Betting', @SeparatedProductID = 0, @ProductCodes = 'SAG'

	SET @StartDate = DATEADD(DAY, 6, @StartDate)
END
GO