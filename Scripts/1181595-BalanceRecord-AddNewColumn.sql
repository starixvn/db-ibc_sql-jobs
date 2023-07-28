/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
use bodb02
go
/*
   Created:Kathy@20230621  
   DB: DBBAH-bodb02
*/
alter table dbo.BalanceTrigger add winlostdate smalldatetime
go
alter table dbo.BalanceTrigger add refno bigint
go
alter table dbo.BalanceTrigger_UAT add winlostdate smalldatetime
go
alter table dbo.BalanceTrigger_UAT add refno bigint
go
alter table dbo.BalanceTrigger_ProcessData add winlostdate smalldatetime
go
alter table dbo.BalanceTrigger_ProcessData add refno bigint
go
alter table dbo.BalanceRecord add winlostdate smalldatetime
go
alter table dbo.BalanceRecord add refno bigint
go

