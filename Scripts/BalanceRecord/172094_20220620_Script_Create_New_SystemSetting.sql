/*<info serverAlias="DBBAH-bodb02"></info>*/
/*
	Created: 20220620@Sol
	Task: Database Improvement - New system setting - [Redmine:172094]
	Database: DBBAH-bodb02
*/
USE bodb02;
GO

---insert new setting to SystemSetting table
INSERT INTO dbo.SystemSettings (
	VName
	, VValue
	)
VALUES (
	'BalanceRecord_LastRowId'
	, '292071406'
	)
GO