/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20220802@July
	Task: Scale out DBTRANS - Detect player exceeded the bet limit of the Agent's setting [Redmine:#175965]
	DB: DBTP/bodb02
	
	Revisions:
		- 20220802@July: Scale out DBTRANS - Update column ConfigValue table dbo.CustMaxBetSetting_Config  - SUPPORT LOCAL [Redmine:#175965]

*/

DECLARE @maxTransId_bettrans		BIGINT 
		,@maxTransId_bettransLC		BIGINT 
		,@maxTransId_bettransRnG	BIGINT 
		,@maxTransId_bettransG		BIGINT 
		,@maxTransId_translog		BIGINT 

SELECT @maxTransId_bettrans = MAX(transid) FROM dbo.bettrans WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettrans
WHERE c.ConfigName = 'bettrans'


SELECT @maxTransId_bettransLC = MAX(transid) FROM dbo.bettransLC WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransLC
WHERE c.ConfigName = 'bettransLC'


SELECT @maxTransId_bettransRnG = MAX(transid) FROM dbo.bettransRnG WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransRnG
WHERE c.ConfigName = 'bettransRnG'


SELECT @maxTransId_bettransG = MAX(transid) FROM dbo.bettransG WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransG
WHERE c.ConfigName = 'bettransG'


SELECT @maxTransId_translog = MAX(translogid) FROM dbo.translog WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_translog
WHERE c.ConfigName = 'translog'