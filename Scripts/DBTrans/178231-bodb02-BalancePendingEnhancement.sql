/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" selecters="" isFunction="0" isNested="0"></info>*/
/*
    Created: Helen@20220927
    Task: 
    DB: DBTXN/bodb02
    
	Revisions:
		- 20220927@Helen: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#178231]
*/
USE bodb02
GO

CREATE TABLE [dbo].[BalCreditSportsPending_Staging]
(
	[ID] [bigint] IDENTITY(1,1),
	[custid] [int] NULL,
	[balance] [money] NULL,
	CONSTRAINT [PK_BalCreditSportsPending_Staging] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) 

GO
CREATE TABLE [dbo].[BalanceUpdateSetting](
	[VName] [varchar](50) NOT NULL,
	[VValue] [varchar](200) NULL,
 CONSTRAINT [PK_BalanceUpdateSetting] PRIMARY KEY CLUSTERED 
(
	[VName] ASC
)
)

GO
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_State',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_rnMIN',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_rnMAX',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_tstamp',CONVERT(VARCHAR(50), sysdatetime()) )
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_updID',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_TotalCust',0)
INSERT INTO dbo.BalanceUpdateSetting (VName, VValue) VALUES ('PendingCS_CreatedDate',CONVERT(VARCHAR(50), GETDATE(),121))

GO



