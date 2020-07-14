/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
	Created: 20200714@Bobby
	Task: ReInit balanceRecord NewBalance - [Redmine:#137483]
	DB: DBBAH-bodb02

*/
use bodb02;
go

-- check custid
--SELECT custid
--  FROM [bodb02].[dbo].[custInfo] with(nolock)
--  where username in (
--	'TLCRMB0146831',
--	'TLCRMB0143125'
--  )

declare 
	@custid int,
	@display bit = 1 --> 1:show only - 0: to update 

set @custid = 24795794;
exec [dbo].[DBA_BalanceRecord_ReInit] @custid = @custid, @display = @display

set @custid = 29045766;
exec [dbo].[DBA_BalanceRecord_ReInit] @custid = @custid, @display = @display
