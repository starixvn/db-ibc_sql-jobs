/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20211129@Kos
	Task: Regen data of table rptCustomerTurnover [RedmineID: #163191]
	DB: DBLIC-bodb_LicenseeReport
*/

USE bodb_LicenseeReport
GO

EXEC Task_rptCustomerTurnOver_Bettrans14 '2021-11-22'
GO

EXEC Task_rptCustomerTurnOver_Bettrans14 '2021-11-23'
GO

EXEC Task_rptCustomerTurnOver_Bettrans14 '2021-11-24'
GO
