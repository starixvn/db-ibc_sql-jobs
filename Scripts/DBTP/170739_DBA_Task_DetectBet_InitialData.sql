/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02	
*/
USE [bodb02]
GO

DECLARE @maxTransId_bettrans BIGINT
	, @maxTransId_bettransLC BIGINT
	, @maxTransId_bettransRnG BIGINT
	, @maxTransId_translog BIGINT

SELECT @maxTransId_bettrans = MAX(transid)
FROM dbo.bettrans WITH (NOLOCK)

SELECT @maxTransId_bettransLC = MAX(transid)
FROM dbo.bettransLC WITH (NOLOCK)

SELECT @maxTransId_bettransRnG = MAX(transid)
FROM dbo.bettransRnG WITH (NOLOCK)

SELECT @maxTransId_translog = MAX(translogid)
FROM dbo.translog WITH (NOLOCK)

INSERT INTO dbo.CustMaxBetSetting_Config (ConfigName, ConfigValue)
SELECT 'bettrans', @maxTransId_bettrans
UNION
SELECT 'bettransLC', @maxTransId_bettransLC
UNION
SELECT 'bettransRnG', @maxTransId_bettransRnG
UNION
SELECT 'translog', @maxTransId_translog
UNION
SELECT 'IsSendTestCurrencyOnly', 0

