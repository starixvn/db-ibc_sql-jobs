/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02	
*/
USE [bodb02]
GO

DECLARE @minTransId_bettrans BIGINT
	, @minTransId_bettransLC BIGINT
	, @minTransId_bettransRnG BIGINT
	, @minTransId_translog BIGINT

SELECT @minTransId_bettrans = MIN(transid)
FROM dbo.bettrans WITH (NOLOCK)

SELECT @minTransId_bettransLC = MIN(transid)
FROM dbo.bettransLC WITH (NOLOCK)

SELECT @minTransId_bettransRnG = MIN(transid)
FROM dbo.bettransRnG WITH (NOLOCK)

SELECT @minTransId_translog = MIN(translogid)
FROM dbo.translog WITH (NOLOCK)

INSERT INTO dbo.CustMaxBetSetting_Config (ConfigName, ConfigValue)
SELECT 'bettrans', @minTransId_bettrans
UNION
SELECT 'bettransLC', @minTransId_bettransLC
UNION
SELECT 'bettransRnG', @minTransId_bettransRnG
UNION
SELECT 'translog', @minTransId_translog
UNION
SELECT 'IsSendTestCurrencyOnly', 0

