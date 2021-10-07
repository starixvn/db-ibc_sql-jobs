/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/

begin transaction
	exec sp_rename 'bettransLC_bk.ip','IP_tmp', 'COLUMN';  
	exec sp_rename 'bettransLC_bk.IP_new','ip', 'COLUMN';  
commit

ALTER TABLE bettransLC_bk
drop column IP_tmp