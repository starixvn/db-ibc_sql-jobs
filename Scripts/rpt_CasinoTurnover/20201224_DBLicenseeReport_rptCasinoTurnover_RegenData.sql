/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20201224@Kos
	Task: Regen data of table rptCasinoTurnover for 2020-12-19 [RedmineID: #146135]
	DB: DBLIC-bodb_LicenseeReport
*/

USE bodb_LicenseeReport
GO

EXEC Task_DailyRptCasinoTurnover_Bettrans14 '2020-12-19'

GO