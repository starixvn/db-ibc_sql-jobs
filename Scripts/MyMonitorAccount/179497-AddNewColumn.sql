/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="" isFunction="0"></info>*/
USE bodb02
GO
ALTER TABLE dbo.WLMonitored_TicketDetails_Pending ADD sWinlost MONEY
GO
ALTER TABLE dbo.WLMonitored_TicketDetails_Pending ADD mWinlost MONEY
GO
ALTER TABLE dbo.WLMonitored_TicketDetails_Pending ADD aWinlost MONEY