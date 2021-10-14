/*<info serverAlias="DBRMS-bodb_RMS" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb_RMS
go

--==ip@rmBettrans
drop index [IX_transdate_IP] ON [dbo].[rmBettrans]
go

alter table rmBettrans alter column [ip] varchar(45)

create nonclustered index [IX_transdate_IP] on [dbo].[rmBettrans]
(
	[transdate] asc,
	[ip] asc
)
include([custid],[liveawayscore]) on [rmIndex]
go

--==ip@rmBettrans_Old
exec sp_rename 'rmBettrans_Old.ip','ip_tmp', 'COLUMN'  
exec sp_rename 'rmBettrans_Old.ip_new','ip', 'COLUMN'
