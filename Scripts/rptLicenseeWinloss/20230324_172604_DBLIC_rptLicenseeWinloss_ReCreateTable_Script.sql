/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - Setup DB structure
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Run on pair DB052-DB053
		- Change [LiveIndicator] from bit to tinyint - dueto Parlay Mixed Live/None
		- Change [Betfrom] Nvarchar(1) to varchar(4)
*/
USE [bodb_LicenseeReport]
GO

TRUNCATE TABLE [dbo].[rptLicenseeWinloss];
GO

ALTER TABLE [dbo].[rptLicenseeWinloss]
ALTER COLUMN [LiveIndicator] [tinyint] NOT NULL;
GO

ALTER TABLE [dbo].[rptLicenseeWinloss]
ALTER COLUMN [Betfrom] [varchar](4) NOT NULL;
GO

ALTER INDEX IX_CustID ON dbo.rptLicenseeWinloss REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO
