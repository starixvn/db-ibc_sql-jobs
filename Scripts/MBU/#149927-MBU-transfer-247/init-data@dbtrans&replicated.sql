
/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBOF-bodb02,DBBAH-bodb02,DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb02
go

--//BeingMovebetDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'BeingMovebetDate'
)
insert into dbo.SystemSettings(VName, VValue) values('BeingMovebetDate', '2021-05-02')

--//MovebetDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MovebetDate'
)
insert into dbo.SystemSettings(VName, VValue) values('MovebetDate', '2021-05-01')

--//Movebet_DoneCopy_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'Movebet_DoneCopy_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('Movebet_DoneCopy_Local', '0')

--//Movebet_DoneSumWinloss_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'Movebet_DoneSumWinloss_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('Movebet_DoneSumWinloss_Local', '0')

--//Movebet_DoneSum19999_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'Movebet_DoneSum19999_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('Movebet_DoneSum19999_Local', '0')
