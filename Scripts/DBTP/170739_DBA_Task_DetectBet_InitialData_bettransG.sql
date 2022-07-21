/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02	
*/
USE [bodb02]
GO

DECLARE @maxTransId_bettransG BIGINT

SELECT @maxTransId_bettransG = MAX(transid)
FROM dbo.bettransG WITH (NOLOCK)

INSERT INTO dbo.CustMaxBetSetting_Config (ConfigName, ConfigValue)
SELECT 'bettransG', @maxTransId_bettransG

