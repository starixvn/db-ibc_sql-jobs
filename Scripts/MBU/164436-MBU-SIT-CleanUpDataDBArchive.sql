/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20211110@Max
	Task: Set up MBU on SIT - [Redmine: #164436]
	DB: DBARC/bodb_Archive

	Notes:
		- Clean up data on bet ticket tables before 29/10/2021 
*/

USE [bodb_Archive]
GO

BEGIN
	TRUNCATE TABLE dbo.bettrans_AGCasino_bk
	TRUNCATE TABLE dbo.bettrans_Staging_bk
	TRUNCATE TABLE dbo.bettrans_bk
	TRUNCATE TABLE dbo.bettransG
	TRUNCATE TABLE dbo.bettransLC_bk
	TRUNCATE TABLE dbo.bettransm
	TRUNCATE TABLE dbo.bettransRnG_bk
	TRUNCATE TABLE dbo.translog_BK
END

