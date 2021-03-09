/*<info serverAlias="DBN88-bodb_N88"></info>*/
use bodb_N88
go

/*
	Created: 20210309@Percy
	DB: DBN88-bodb_N88
	Task: Repull data manually (Deposit + Withdrawal)
*/

/*
select min(DepositId)
from dbo.DepositInfo with (nolock)
where WinlostDate = '2021-02-01'

select min(WithdrawalId)
from dbo.WithdrawalInfo with (nolock)
where WinlostDate = '2021-02-01'
*/

insert into dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
values ('DepositInfo', GETDATE(), 135813)
	,('WithdrawalInfo', GETDATE(), 33480)