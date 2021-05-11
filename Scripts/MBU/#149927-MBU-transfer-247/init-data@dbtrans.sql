
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb02
go

--==Movebet_ReadyUpdMBDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'Movebet_ReadyUpdMBDate'
)
insert into dbo.SystemSettings(VName, VValue) values('Movebet_ReadyUpdMBDate', '0')

