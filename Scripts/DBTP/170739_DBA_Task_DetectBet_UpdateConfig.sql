/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02	
*/
USE [bodb02]
GO

UPDATE c SET c.ConfigValue = '1'
FROM dbo.CustMaxBetSetting_Config c WITH (ROWLOCK, UPDLOCK)
WHERE c.ConfigName = 'IsSendTestCurrencyOnly'

