/*<info serverAlias="DBN88-bodb_N88"></info>*/

/*
	Created: 20201021@Percy
	DB: DBN88-bodb_N88
	Task: Nova cash - Add new table AdjustmentInfo
*/

use bodb_N88
go

create table dbo.AdjustmentInfo
(
	AdjustId int not null
	,TransId varchar(30)
	,AdjustType tinyint
	,CustId int
	,UserName varchar(30)
	,CurrencyId tinyint
	,SiteId int
	,AdjustIdInfo nvarchar(max)
	,Amount decimal(18,4)
	,CreateTime datetime
	,FirstDeposit bit
	,RefId varchar(100)
	,Memo varchar(500)
	,Comment varchar(500)
	,Status tinyint
	,WinlostDate as convert(date, CreateTime)
	,constraint PK_AdjustmentInfo primary key nonclustered
	(
		AdjustId asc
	) on ReportData
) on ReportData
go

create clustered index CIX_AdjustmentInfo on dbo.AdjustmentInfo (WinlostDate) on ReportData
go