/*
	Created: 201911212@Bobby
	DB: DB06x.bodb_archive
	Task: Add temporary table to re-genertae data up to 2018-12-13 previous year [RedmineID #125358]
*/
use bodb_archive
go
create table dbo.rptLicPromotion_xpre
(
	RptDate date,
	CustId int,
	RptDateGMT date,
	BetCount Int,
	BetCount_WonLose Int,
	Turnover money,
	Turnover_WonLose money
) ON [DATA]
CREATE UNIQUE CLUSTERED INDEX CIX_RptDate ON dbo.rptLicPromotion_xpre(
	RptDate ASC,
	CustId ASC,
	RptDateGMT ASC
) ON [DATA]