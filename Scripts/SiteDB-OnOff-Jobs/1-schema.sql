/*<info serverAlias="DBSIG-bodb02"></info>*/
use bodb02
go
create table dbo.Task_DBA_AG_Jobs_List
(
	JobName varchar(128) not null,
	PriorityLevel smallint,
	Ignore BIT DEFAULT(0)
)
alter table [dbo].[Task_DBA_AG_Jobs_List] add  constraint [PK_Task_DBA_AG_Jobs_List] primary key nonclustered 
(
	[JobName] ASC
)


insert into Task_DBA_AG_Jobs_List(JobName, PriorityLevel, Ignore)
select name, 99, 0 from msdb.dbo.sysjobs

--for new 2 jobs
insert into Task_DBA_AG_Jobs_List(JobName, PriorityLevel, Ignore)
values('DBA_AG_Switch_Jobs_Monitor', 99, 1), ('DBA_AG_Switch_Jobs', 99, 1)

--for reset sequence
update Task_DBA_AG_Jobs_List
set PriorityLevel = 1
where JobName in ('DBA_Reset_Bet_Sequence', 'DBA_Reset_BetX_Sequence', 'DBA_Reset_Refno_Sequence')

--for update balance
update Task_DBA_AG_Jobs_List
set PriorityLevel = 2
where JobName like 'bodb02 : Task_BalanceUpd%'
	or JobName = 'bodb02 : Game : Task_BalanceUpd'

--for update settlement
update Task_DBA_AG_Jobs_List
set PriorityLevel = 3
where JobName like 'bodb02 : NAP %'

--ignore it if got disabled
update l set Ignore = 1
from Task_DBA_AG_Jobs_List l
	inner join msdb.dbo.sysjobs j on l.JobName = j.name
where j.enabled = 0

--special cases
update l set Ignore = 1
from Task_DBA_AG_Jobs_List l
where JobName IN ('syspolicy_purge_history'
	, 'DBA : Send SQL Service Restart Alert Mail'
	, 'DBA_Script_Instance_Object'
	, 'DBA_Full_Backup'
	, 'DBA : MonDB Get DB Info'
	, 'DBA_Txn_Backup'
	, 'DBA_Switch_Errorlog'
	, 'DBA_Deadlock_Monitor'
	, 'DBA_Diff_Backup'
	, 'DBA_AG_Switch_Jobs'
	, 'DBA_AG_Switch_Jobs_Monitor'
)

select * from Task_DBA_AG_Jobs_List order by PriorityLevel
