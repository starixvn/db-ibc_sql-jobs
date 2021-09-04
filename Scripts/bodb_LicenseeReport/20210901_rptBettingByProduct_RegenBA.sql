/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20210901@Percy
	DB: DBLIC-bodb_LicenseeReport
	Task: Regen data for BA products
*/

USE bodb_LicenseeReport
GO

DECLARE @WinlostDate DATE = '2021-08-28', @Msg VARCHAR(100)

WHILE @WinlostDate < '2021-09-01'
BEGIN
	SELECT @Msg = 'Start date: ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
	RAISERROR (@Msg, 1, 0) WITH NOWAIT

	EXEC dbo.GEN_rptBettingByProduct
		@date = @WinlostDate
		,@date2 = @WinlostDate
		,@DataSource = 'rpt_betting'
		,@ProductCodes = 'BA'
		,@SeparatedProductID = 0   
		,@IsManual = 1

	WAITFOR DELAY '00:00:00.280'

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END
GO