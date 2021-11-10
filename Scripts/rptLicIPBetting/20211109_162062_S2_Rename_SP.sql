/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBLIC-bodb_licensee,DBLIC-bodb02"></info>*/
/*	
	Created: 20211109@Sol
	DB: DBLIC-bodb_LicenseeReport,DBLIC-bodb_licensee,DBLIC-bodb02
	RedmineID: Stop Automail Licensee Current Play report - [Redmine:162062]
 
*/
 
USE bodb_licensee

GO

EXEC sp_rename 'Lrf_Rpt_MonthlyLicCurrencyPlay', 'DEL_Lrf_Rpt_MonthlyLicCurrencyPlay'

GO

USE bodb_LicenseeReport

GO

EXEC sp_rename 'Task_DailyRptLicIPBetting', 'DEL_Task_DailyRptLicIPBetting'
EXEC sp_rename 'Task_DailyRptLicIPBetting_Archive', 'DEL_Task_DailyRptLicIPBetting_Archive'
EXEC sp_rename 'Task_DailyRptLicIPBetting_Job', 'DEL_Task_DailyRptLicIPBetting_Job'

GO

USE bodb02

GO

EXEC sp_rename 'Task_RptLicIPBetting_UpdateCountry', 'DEL_Task_RptLicIPBetting_UpdateCountry'
