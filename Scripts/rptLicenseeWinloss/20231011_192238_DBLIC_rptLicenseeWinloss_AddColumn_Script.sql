
/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20231011@Evan
	Task: 192238 - LAP - Winloss Analysis - Integrate Parlay Boost - Add new column
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Run on pair DB052-DB053
*/

USE bodb_LicenseeReport
GO
ALTER TABLE [dbo].[rptLicenseeWinloss]
ADD ExtraInfo NVARCHAR(4000)

GO