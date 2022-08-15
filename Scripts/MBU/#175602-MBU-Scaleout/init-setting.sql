/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
use bodb02
go

insert into SystemSettings(VName, VValue)
values('Fri-routine-f', '0')
	, ('Fri-routine-s', '2022-08-05')
	, ('BU_Sum20k_Local', '0')
	, ('BU_ReadyUpdBUDate', '0')