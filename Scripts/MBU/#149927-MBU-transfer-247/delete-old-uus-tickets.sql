/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO


delete top (3) from dbo.bettrans with(rowlock)
where transid in (8407270332, 8407270983)
	and custid in (14242878, 14242878)

go
