/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
---bettransRnG_bk
--++add new column
alter table bettrans_bk add ip_new varchar(45)

--UM

--exec sp_rename 'bettrans_bk.ip','ip_tmp', 'COLUMN'  
--exec sp_rename 'bettrans_bk.ip_new','ip', 'COLUMN'

go
