/*<info serverAlias="DBLIC-bodb_3rdProduct"></info>*/

/*
	Created: 20200818@Percy
	DB: DBLIC.bodb_3rdProduct
	Task: Exchange - Integrate new game type: Fancy bet
*/

use bodb_3rdProduct
go

alter table dbo.bettrans_exchange
	alter column eventType int
go

alter table dbo.bettrans_exchange
	add fancyBetRuns money
		,categoryType smallint
go

alter table dbo.bettransM_exchange
	add txFancyBetRuns money
go


use bodb_LicenseeReport
go

alter table dbo.rptDepWinlost_ThirdParty_Performance
	drop constraint CIX_rptDepWinlost_ThirdParty_Performance
go

alter table dbo.rptDepWinlost_ThirdParty_Performance
	alter column sporttype int not null
go

alter table dbo.rptDepWinlost_ThirdParty_Performance
	add constraint CIX_rptDepWinlost_ThirdParty_Performance primary key clustered
	(
		Winlostdate asc
		,ProductId asc
		,Custid asc
		,Sporttype asc
	) on rptDepWinlost_ThirdPartyData
go


use bodb_LicenseeReport
go
alter table dbo.Sports_ThirdParty
	drop constraint CIX_Sports_ThirdParty
go

alter table dbo.Sports_ThirdParty
	alter column sporttype int not null
go

alter table dbo.Sports_ThirdParty
	add constraint CIX_Sports_ThirdParty primary key clustered
	(
		ProductId asc
		,Sporttype asc
	) on rptDepWinlost_ThirdPartyData
go
