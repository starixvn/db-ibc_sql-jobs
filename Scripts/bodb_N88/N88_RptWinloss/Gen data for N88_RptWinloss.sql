/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210305@Percy
	DB: DBN88-bodb_N88
	Task: Regen data manually
*/

USE bodb_N88
GO

DECLARE @WinlostDate SMALLDATETIME, @ErrMsg VARCHAR(50)

SELECT  @WinlostDate = '2020-01-20'

WHILE @WinlostDate < '2021-03-01'
BEGIN
	SELECT @ErrMsg = 'Start Date: ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
	RAISERROR (@ErrMsg, 0, 1) WITH NOWAIT

	EXEC dbo.Task_N88_RptWinloss @WinlostDate = @WinlostDate

	SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)

	WAITFOR DELAY '00:00:00.280'
END