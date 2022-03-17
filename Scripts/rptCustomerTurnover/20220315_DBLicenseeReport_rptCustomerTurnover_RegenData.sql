/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20220315@Hogan
	Task: Regen Virtual Sports 3 data in table rptCustomerTurnover [RedmineID: #145337]
	DB: DBLIC-bodb_LicenseeReport
*/

USE bodb_LicenseeReport
GO

EXEC Task_rptCustomerTurnOver_Bettrans14 '2022-03-10'
GO

EXEC Task_rptCustomerTurnOver_Bettrans14 '2022-03-11'
GO