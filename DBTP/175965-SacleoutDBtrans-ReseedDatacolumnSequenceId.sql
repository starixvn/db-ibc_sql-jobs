/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20220802@July
	Task: Scale out DBTRANS - Detect player exceeded the bet limit of the Agent's setting [Redmine:#175965]
	DB: DBTXN/bodb02
	
	Revisions:
		- 20220802@July: Reseed data  [Redmine:#175965]

*/

DECLARE @maxTransId_bettrans BIGINT
		, @maxTransId_bettransLC BIGINT
		, @maxTransId_bettransRnG BIGINT
		, @maxTransId_bettransG BIGINT
		, @maxTransId_translog BIGINT

DBCC CHECKIDENT ('bettrans')
SELECT @maxTransId_bettrans = MAX(transid) FROM dbo.bettrans WITH (NOLOCK)
SELECT 'bettrans', @maxTransId_bettrans
DBCC CHECKIDENT ('bettrans', RESEED,@maxTransId_bettrans)

DBCC CHECKIDENT ('bettransLC')
SELECT @maxTransId_bettransLC = MAX(transid) FROM dbo.bettransLC WITH (NOLOCK)
SELECT 'bettransLC', @maxTransId_bettransLC
DBCC CHECKIDENT ('bettransLC', RESEED,@maxTransId_bettransLC)

DBCC CHECKIDENT ('bettransRnG')
SELECT @maxTransId_bettransRnG = MAX(transid) FROM dbo.bettransRnG WITH (NOLOCK)
SELECT 'bettransRnG', @maxTransId_bettransRnG
DBCC CHECKIDENT ('bettransRnG', RESEED,@maxTransId_bettransRnG)

DBCC CHECKIDENT ('bettransG')
SELECT @maxTransId_bettransG = MAX(transid) FROM dbo.bettransG WITH (NOLOCK)
SELECT 'bettransG', @maxTransId_bettransG
DBCC CHECKIDENT ('bettransG', RESEED,@maxTransId_bettransG)

DBCC CHECKIDENT ('translog')
SELECT @maxTransId_translog = MAX(translogid) FROM dbo.translog WITH (NOLOCK)
SELECT 'translog', @maxTransId_translog
DBCC CHECKIDENT ('translog', RESEED,@maxTransId_translog)


