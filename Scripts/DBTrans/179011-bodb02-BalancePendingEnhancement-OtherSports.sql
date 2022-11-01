/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" selecters="" isFunction="0" isNested="0"></info>*/
/*
    Created: Helen@20220927
    Task: 
    DB: DBTXN/bodb02
    
	Revisions:
		- 20221017@Helen: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#179011]
*/
USE bodb02
GO
CREATE TABLE [dbo].[BalCreditOthersPending_Staging]
(
	[ID] [bigint] IDENTITY(1,1),
	[custid] [int] NULL,
	[balance] [money] NULL,
	CONSTRAINT [PK_BalCreditOthersPending_Staging] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) 
ON [balance_group]

GO
CREATE TABLE [dbo].[BalCreditCasinoPending_Staging]
(
	[ID] [bigint] IDENTITY(1,1),
	[custid] [int] NULL,
	[balance] [money] NULL,
	CONSTRAINT [PK_BalCreditCasinoPending_Staging] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) 
ON [balance_group]

GO
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_State',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_rnMIN',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_rnMAX',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_tstamp',CONVERT(VARCHAR(50), SYSDATETIME()) )
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_updID',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_TotalCust',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingOS_CreatedDate',CONVERT(VARCHAR(50), GETDATE(),121))

GO

GO
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_State',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_rnMIN',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_rnMAX',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_tstamp',CONVERT(VARCHAR(50), SYSDATETIME()) )
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_updID',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_TotalCust',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingLiveCS_CreatedDate',CONVERT(VARCHAR(50), GETDATE(),121))

GO
