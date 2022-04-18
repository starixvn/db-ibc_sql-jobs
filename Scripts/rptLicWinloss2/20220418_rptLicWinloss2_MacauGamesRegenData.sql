/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/

/*
	Created: 20220418@Hogan
	Task: Generate data of Macau Games [RedmineID: #170607]
	DB: DBLIC-bodb_LicenseeReport
	Remark: Regen data for Macau Games
*/

USE bodb_LicenseeReport
GO

EXEC dbo.Task_DailyRptLicWinloss2_Bettrans @winlostdate = '2022-04-15 00:00:00'	