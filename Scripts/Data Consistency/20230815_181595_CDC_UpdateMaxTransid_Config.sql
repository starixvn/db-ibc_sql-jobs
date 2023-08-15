/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Created by: 20230815@July
	Task: Check ticket data consistency - Update maxtransid
	DB: DBSIG-bodb02
	Revisions:
		- 20230815@July:  Inital Writing
*/

USE [bodb02]
GO

DECLARE		@maxTransId_bettrans BIGINT
			, @maxTransId_bettransLC BIGINT
			, @maxTransId_bettransG BIGINT
			, @maxTransId_bettransRnG BIGINT
			, @maxTransId_translog BIGINT
			, @maxTransId_Transfer BIGINT
			, @maxTransId_bettransm BIGINT

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

SELECT	@maxTransId_bettransm = MAX(transid)
FROM	dbo.bettransm WITH (NOLOCK)

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettrans,0)
WHERE ConfigName = 'bettrans'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettransLC,0)
WHERE ConfigName = 'bettransLC'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettransG,0)
WHERE ConfigName = 'bettransG'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettransRnG,0)
WHERE ConfigName = 'bettransRnG'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_translog,0)
WHERE ConfigName = 'translog'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_Transfer,0)
WHERE ConfigName = 'Transfer'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettransm,0)
WHERE ConfigName = 'bettransm'