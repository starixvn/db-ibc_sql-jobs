/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210729@Percy
	DB: DBN88-bodb_N88
	Task: Regen data for Jackpot
	https://nexdev.net/issues/158438
	
*/
use bodb_N88
go

declare @WinlostDate smalldatetime = '2021-05-01', @msg varchar(100)

while @WinlostDate <= '2021-07-29'
begin
	set @msg = 'Start date = ' + convert(varchar(10), @WinlostDate, 120)
	raiserror (@msg, 1, 0) with nowait

	exec dbo.Task_N88_SumWinloss @WinlostDate = @WinlostDate

	set @WinlostDate = dateadd(day, 1, @WinlostDate)
end