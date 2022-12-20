
/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02"></info>*/
--==MBUSettings
create table dbo.MBUSettings (
	VName varchar(64) not null,
	VValue varchar(255) null
)

alter table dbo.MBUSettings add constraint [PK_MBUSettings] primary key clustered (
	[VName] asc
) on [data]

go

--==MBUSettingsHistory
create table dbo.MBUSettingsHistory (
	Id int identity(1,1) not null,
	VName varchar(64) null,
	VValue varchar(255) null,
	CreatedDateTime datetime2 null,
	ActionType varchar(1) null
)

create clustered index CIX_MBUSettingsHistory on MBUSettingsHistory(CreatedDateTime) on [data]
alter table dbo.MBUSettingsHistory add constraint [DF_MBUSettingsHistory_CreatedDateTime]  default ((sysdatetime())) for [CreatedDateTime]

go