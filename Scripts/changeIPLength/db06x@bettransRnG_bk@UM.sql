/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb_Archive
go
--UM
exec sp_rename 'bettransRnG_bk.ip','ip_tmp', 'COLUMN'  
exec sp_rename 'bettransRnG_bk.ip_new','ip', 'COLUMN'

go

