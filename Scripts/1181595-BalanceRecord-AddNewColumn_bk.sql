/*<info serverAlias="DBBAH-balancerecord" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:Kathy@20230621  
   DB: DBBAH-balancerecord
*/
use balancerecord
go

alter table dbo.BalanceRecord_bk add winlostdate smalldatetime
go

alter table dbo.BalanceRecord_bk add refno bigint
