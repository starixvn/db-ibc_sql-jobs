/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20220802@July
	Task: Scale out DBTRANS - Detect player exceeded the bet limit of the Agent's setting [Redmine:#175965]
	DB: DBTP/bodb02
	
	Revisions:
		- 20220802@July: Scale out DBTRANS - Update column ConfigValue table dbo.CustMaxBetSetting_Config [Redmine:#175965]

*/

DECLARE @maxTransId_bettrans		BIGINT = xxx
		,@maxTransId_bettransLC		BIGINT = xxx
		,@maxTransId_bettransRnG	BIGINT = xxx
		,@maxTransId_bettransG		BIGINT = xxx
		,@maxTransId_translog		BIGINT = xxx

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettrans
WHERE c.ConfigName = 'bettrans'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransLC
WHERE c.ConfigName = 'bettransLC'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransRnG
WHERE c.ConfigName = 'bettransRnG'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_bettransG
WHERE c.ConfigName = 'bettransG'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxTransId_translog
WHERE c.ConfigName = 'translog'