/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20220922@Victoria
	Task: 
	DB: DBSIG-bodb02
	Revisions:
		- 20220922@Victoria:  Inital Writing [Redmine:#175881]
*/

USE [bodb02]
GO

DECLARE		@maxTransId_bettransm BIGINT

SELECT	@maxTransId_bettransm = MAX(transid)
FROM	dbo.bettransm WITH (NOLOCK)

INSERT INTO dbo.SiteDB_DataConsistencyCheck_Config (ConfigName, ConfigValue)
SELECT 'bettransm', ISNULL(@maxTransId_bettransm,0)