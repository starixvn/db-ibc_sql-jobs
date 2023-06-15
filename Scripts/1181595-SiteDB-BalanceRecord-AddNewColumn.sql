/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:Kathy@20230621  
   DB: DBSIG-bodb02
*/
use bodb02
go

alter table dbo.BalanceTrigger add winlostdate smalldatetime
go
alter table dbo.BalanceTrigger add refno bigint
