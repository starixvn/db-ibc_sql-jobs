
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb02
go

--==MB_ReadyUpdMBDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MB_ReadyUpdMBDate'
)
insert into dbo.SystemSettings(VName, VValue) values('MB_ReadyUpdMBDate', '0')

