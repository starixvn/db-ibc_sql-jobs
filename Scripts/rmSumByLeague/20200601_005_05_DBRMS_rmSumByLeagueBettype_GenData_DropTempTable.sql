/*<info serverAlias="DBARC-bodb_Archive"></info>*/
USE bodb_Archive
GO

/*
	Created: 20200601@Percy
	DB: DBARC-bodb_Archive
	Task: Gen data for new tables rmSumByLeague, rmSumByBettype

	Drop temp table
*/

DROP TABLE dbo.rmSumByBettype_xtest
GO

DROP TABLE dbo.rmSumByLeague_xtest
GO