/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20231101@Cherry
	DB: DBRMS-bodb_RMS
	Task: Parlay Generator
	RedmineID: 195498

*/

USE bodb_RMS
GO

ALTER TABLE dbo.rmBettrans
ADD ExtraInfo VARCHAR(1000) NULL
GO

ALTER TABLE dbo.rmBettrans_Old
ADD ExtraInfo VARCHAR(1000) NULL
GO