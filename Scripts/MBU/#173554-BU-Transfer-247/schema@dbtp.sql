/*<info serverAlias="DBTP-bodb02"></info>*/

--only dbtp
--==MBUSettingsMonitor
create table dbo.MBUSettingsMonitor (
	Id int not null,
	VName varchar(64) null,
	VValue varchar(255) null,
	CreatedDateTime datetime2 null,
	ActionType varchar(1) null,
	ServerName varchar(125) null,
	RecordTime datetime2 null
)

create clustered index CIX_MBUSettingsMonitor on MBUSettingsMonitor(RecordTime) on [data]
alter table dbo.MBUSettingsMonitor add constraint [DF_MBUSettingsMonitor_RecordTime]  default ((sysdatetime())) for [RecordTime]
create index IX_MBUSettingsMonitor_ServerName on MBUSettingsMonitor(ServerName) include(CreatedDateTime,Id) on [data]

go