
/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBOF-bodb02,DBBAH-bodb02,DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
  
use bodb02
go

--//BeingMovebetDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'BeingMovebetDate'
)
insert into dbo.SystemSettings(VName, VValue) values('BeingMovebetDate', NULL)

--//MovebetDate
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MovebetDate'
)
begin
	declare @__mbdate smalldatetime
	select @__mbdate = max(eventdate) from dbo.match14
	insert into dbo.SystemSettings(VName, VValue) values('MovebetDate', convert(varchar(10), @__mbdate, 121))
end
--//MB_DoneCopy_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MB_DoneCopy_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('MB_DoneCopy_Local', '0')

--//MB_SWinloss_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MB_SWinloss_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('MB_SWinloss_Local', '0')

--//MB_Sum19999_Local
if not exists (
	select top 1 1 from dbo.SystemSettings where VName = 'MB_Sum19999_Local'
)
insert into dbo.SystemSettings(VName, VValue) values('MB_Sum19999_Local', '0')

    
