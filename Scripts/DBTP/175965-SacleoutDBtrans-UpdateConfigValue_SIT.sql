/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20220802@July
	Task: Scale out DBTRANS - Detect player exceeded the bet limit of the Agent's setting [Redmine:#175965]
	DB: DBTP/bodb02
	
	Revisions:
		- 20220802@July: Scale out DBTRANS - Update column ConfigValue table dbo.CustMaxBetSetting_Config  - SUPPORT SIT [Redmine:#175965]

*/

DECLARE @maxSequenceId_bettrans			BIGINT 
		,@maxSequenceId_bettransLC		BIGINT 
		,@maxSequenceId_bettransRnG		BIGINT 
		,@maxSequenceId_bettransG		BIGINT 
		,@maxSequenceId_translog		BIGINT 

SELECT @maxSequenceId_bettrans = MAX(sequenceid) FROM dbo.bettrans WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxSequenceId_bettrans
WHERE c.ConfigName = 'bettrans'


SELECT @maxSequenceId_bettransLC = MAX(sequenceid) FROM dbo.bettransLC WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxSequenceId_bettransLC
WHERE c.ConfigName = 'bettransLC'


SELECT @maxSequenceId_bettransRnG = MAX(sequenceid) FROM dbo.bettransRnG WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxSequenceId_bettransRnG
WHERE c.ConfigName = 'bettransRnG'


SELECT @maxSequenceId_bettransG = MAX(sequenceid) FROM dbo.bettransG WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxSequenceId_bettransG
WHERE c.ConfigName = 'bettransG'


SELECT @maxSequenceId_translog = MAX(sequenceid) FROM dbo.translog WITH(NOLOCK)
UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = @maxSequenceId_translog
WHERE c.ConfigName = 'translog'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = 0
WHERE c.ConfigName = 'IsSendTestCurrencyOnly'

UPDATE dbo.CustMaxBetSetting_Config
SET ConfigValue = GETDATE()
WHERE c.ConfigName = 'SyncHistoryDataLastTime'