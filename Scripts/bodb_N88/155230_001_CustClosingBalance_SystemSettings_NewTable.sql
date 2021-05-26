/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210524@Percy
	DB: DBN88-bodb_N88
	Task: New table CustClosingBalance, SystemSettings
*/

use bodb_N88
go

create table dbo.CustClosingBalance
(
	Time		datetime not null,
	CustId		int not null,
	SiteId		int not null,
	Balance		decimal(20, 4),
	CreateTime	datetime,
	constraint PK_CustClosingBalance primary key
	(
		Time asc,
		CustId asc,
		SiteId asc
	)
) on ReportData
go

create table dbo.SystemSettings
(
	Id		int not null identity(1, 1),
	SName	varchar(50) not null,
	SValue	varchar(200),
	constraint PK_SystemSettings primary key nonclustered
	(
		Id asc
	)
) on SettingData
go

create clustered index CIX_SystemSettings on dbo.SystemSettings (SName) on SettingData
go

insert into dbo.SystemSettings (SName, SValue)
values ('RepullData_Date', '2021-05-24')
go