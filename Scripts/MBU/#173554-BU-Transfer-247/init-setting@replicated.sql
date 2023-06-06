/*<info serverAlias="DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02"></info>*/

select * from MBUSettings

--delete from dbo.MBUSettings

declare @__currentBalanceUpDate varchar(10)
select @__currentBalanceUpDate = convert(varchar(10), winlostdate, 121) 
from dbo.Transfer with(nolock) where CustId = 3 and bettype = 20000

--add new
insert into MBUSettings(VName, VValue)
values('BU_Sum20k_Local', '0')
	, ('BeingBalanceUpDate', null)
	, ('BalanceUpDate', @__currentBalanceUpDate)
	, ('BU_UpdBUDate_Local', '0')
	, ('StartBalanceUp_Local', convert(varchar(50), getdate(), 121)) --init
	, ('EndBalanceUp_Local', convert(varchar(50), getdate(), 121)) --init

update s 
set VValue = (select ss.VValue from dbo.SystemSettings ss with(nolock) where ss.VName = 'StartMoving_Local')
from dbo.MBUSettings s
where s.VName in ('StartBalanceUp_Local')

update s 
set VValue = (select ss.VValue from dbo.SystemSettings ss with(nolock) where ss.VName = 'EndMoving_Local')
from dbo.MBUSettings s
where s.VName in ('EndBalanceUp_Local')


go
