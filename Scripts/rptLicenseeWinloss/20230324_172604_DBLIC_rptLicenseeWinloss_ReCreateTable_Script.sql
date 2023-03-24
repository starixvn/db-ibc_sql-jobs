/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - Setup DB structure
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Run on pair DB052-DB053
		- Change [LiveIndicator] from bit to tinyint - dueto Parlay Mixed Live/None
*/
USE [bodb_LicenseeReport]
GO

ALTER TABLE [dbo].[rptLicenseeWinloss]
ALTER COLUMN [LiveIndicator] [tinyint] NOT NULL;
