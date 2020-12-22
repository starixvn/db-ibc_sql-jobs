/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20201201@Mark
	DB: DBLIC-bodb_LicenseeReport
	Task: Add Column TicketType To Table rptCasinoTurnover
	RedmineID: #146135 - LAP - Casino Turnover Report - Support Saba.club, PP and PG Soft products
*/

USE bodb_LicenseeReport
GO

ALTER TABLE dbo.rptCasinoTurnover
	ADD TicketType  TINYINT;
GO