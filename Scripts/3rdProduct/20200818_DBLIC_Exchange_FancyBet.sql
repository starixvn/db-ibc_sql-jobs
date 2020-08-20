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