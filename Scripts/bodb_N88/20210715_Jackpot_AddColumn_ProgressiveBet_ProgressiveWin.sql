/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210715@Percy
	DB: DBN88-bodb_N88
	Task: Add new column: ProgressiveBet, ProgressiveWin for Jackpot
*/
use bodb_N88
go

alter table dbo.TpBetRecord
	add ProgressiveBet decimal(20, 4)
		,ProgressiveWin decimal(20, 4)
go

alter table dbo.N88_SumWinloss
	add ProgressiveBet money
		,ProgressiveWin money
go
	