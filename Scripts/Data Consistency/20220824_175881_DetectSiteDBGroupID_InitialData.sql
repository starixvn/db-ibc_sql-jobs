/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20220824@Victoria
	Task: 
	DB: DBSIG-bodb02
	Revisions:
		- 20220824@Victoria:  Inital Writing [Redmine:#175881]
*/

USE [bodb02]
GO

DECLARE		@maxTransId_bettrans BIGINT
			, @maxTransId_bettransLC BIGINT
			, @maxTransId_bettransG BIGINT
			, @maxTransId_bettransRnG BIGINT
			, @maxTransId_translog BIGINT
			, @maxTransId_Transfer BIGINT

SELECT	@maxTransId_bettrans = MAX(transid)
FROM	dbo.bettrans WITH (NOLOCK)

SELECT	@maxTransId_bettransLC = MAX(transid)
FROM	dbo.bettransLC WITH (NOLOCK)

SELECT	@maxTransId_bettransG = MAX(transid)
FROM	dbo.bettransG WITH (NOLOCK)

SELECT	@maxTransId_bettransRnG = MAX(transid)
FROM	dbo.bettransRnG WITH (NOLOCK)

SELECT	@maxTransId_translog = MAX(translogid)
FROM	dbo.translog WITH (NOLOCK)

SELECT	@maxTransId_Transfer = MAX(TransId)
FROM	dbo.Transfer WITH (NOLOCK)

INSERT INTO dbo.SiteDB_DataConsistencyCheck_Config (ConfigName, ConfigValue)
SELECT 'bettrans', ISNULL(@maxTransId_bettrans,0)
UNION
SELECT 'bettransLC', ISNULL(@maxTransId_bettransLC,0)
UNION
SELECT 'bettransG', ISNULL(@maxTransId_bettransG,0)
UNION
SELECT 'bettransRnG', ISNULL(@maxTransId_bettransRnG,0)
UNION
SELECT 'translog', ISNULL(@maxTransId_translog,0)
UNION
SELECT 'Transfer', ISNULL(@maxTransId_Transfer,0)