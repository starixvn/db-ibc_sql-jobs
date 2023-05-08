/*
	Created: 20230508@Brice
	DB: DB06x.bodb_archive
	Task: extend betfrom column datatype [RedmineID #126137]
*/

/*----script get alter command
use bodb_archive
go
select top 100 OBJECT_NAME(c.object_id),c.name,c.max_length,t.name,
CONCAT('alter table ',OBJECT_NAME(c.object_id), ' alter column betfrom ',t.name,'(4) null')
from sys.all_columns c (nolock) join sys.types t (nolock) on c.system_type_id = t.user_type_id
where OBJECT_NAME(c.object_id) in ('bettransG','translog_BK','bettransRnG_bk','bettransLC_bk','zzzbettrans_bk','zzzbettransm_bk','bettransm','bettrans_bk')
and c.name = 'betfrom'
order by OBJECT_NAME(c.object_id)
*/


use bodb_archive
go
alter table bettrans_bk alter column betfrom varchar(4) null
alter table bettransG alter column betfrom nvarchar(4) null
alter table bettransLC_bk alter column betfrom varchar(4) null
alter table bettransm alter column betfrom varchar(4) null
alter table bettransRnG_bk alter column betfrom varchar(4) null
alter table translog_BK alter column betfrom nvarchar(4) null
alter table zzzbettrans_bk alter column betfrom nvarchar(4) null
alter table zzzbettransm_bk alter column betfrom nvarchar(4) null