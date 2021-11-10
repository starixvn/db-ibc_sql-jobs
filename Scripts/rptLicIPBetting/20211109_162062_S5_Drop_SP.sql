/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBLIC-bodb_licensee,DBLIC-bodb02"></info>*/
/*	
	Created: 20211109@Sol
	DB: DBLIC-bodb_LicenseeReport,DBLIC-bodb_licensee,DBLIC-bodb02
	RedmineID: Stop Automail Licensee Current Play report - [Redmine:162062]
 
*/
 
USE bodb_licensee

GO

DROP PROCEDURE DEL_Lrf_Rpt_MonthlyLicCurrencyPlay

GO

USE bodb_LicenseeReport

GO

DROP PROCEDURE DEL_Task_DailyRptLicIPBetting
DROP PROCEDURE DEL_Task_DailyRptLicIPBetting_Archive
DROP PROCEDURE DEL_Task_DailyRptLicIPBetting_Job

GO

USE bodb02

GO

DROP PROCEDURE DEL_Task_RptLicIPBetting_UpdateCountry
