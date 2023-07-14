/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Created by: 20230706@July
	Task: Check ticket data consistency - Update maxtransid
	DB: DBSIG-bodb02
	Revisions:
		- 20230706@July:  Inital Writing
*/

USE [bodb02]
GO

DECLARE		@maxTransId_bettrans BIGINT
		, @maxTransId_Transfer BIGINT
SELECT	@maxTransId_bettrans = MAX(transid)
FROM	dbo.bettrans WITH (NOLOCK)

SELECT	@maxTransId_Transfer = MAX(TransId)
FROM	dbo.Transfer WITH (NOLOCK)


UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_bettrans,0)
WHERE ConfigName = 'bettrans'

UPDATE dbo.SiteDB_DataConsistencyCheck_Config
SET ConfigValue = ISNULL(@maxTransId_Transfer,0)
WHERE ConfigName = 'Transfer'