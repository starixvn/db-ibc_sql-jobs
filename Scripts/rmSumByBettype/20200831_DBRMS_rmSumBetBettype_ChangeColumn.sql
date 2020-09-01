/*<info serverAlias="DBRMS-bodb_RMS" ></info>*/

/*
	Created: 20200831@Percy
	DB: DBRMS-bodb_RMS
	Task: Sum by Bettype
		rmSumByBettype - Change column LeagueIds (varchar) to LeagueId (int)
*/

use bodb_RMS
go

-- run first
alter table dbo.rmSumByBettype
	add LeagueId int
go



-- run after deploy all packages
alter table dbo.rmSumByBettype
	drop column LeagueIds
go