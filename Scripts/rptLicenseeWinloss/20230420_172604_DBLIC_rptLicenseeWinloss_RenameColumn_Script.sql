/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230420@Bobby
	Task: 172604 - LAP - Winloss Analysis - Setup DB structure
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Run on pair DB052-DB053
*/
use [bodb_LicenseeReport]
go
  
EXEC sp_rename 'dbo.rptLicenseeWinloss.PComm', 'AWinlost1', 'COLUMN';
EXEC sp_rename 'dbo.rptLicenseeWinloss.AWinlost', 'PComm', 'COLUMN';
EXEC sp_rename 'dbo.rptLicenseeWinloss.AWinlost1', 'AWinlost', 'COLUMN';