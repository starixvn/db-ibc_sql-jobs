/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210301@Percy
	DB: DBN88-bodb_N88
	Task: Add new column Revenue
*/

USE bodb_N88
GO

ALTER TABLE dbo.TpBetRecord
	ADD Revenue DECIMAL(20, 4)
GO

-- Include new column Revenue into Index IX_WinlostDate_TicketStatus
DROP INDEX [IX_WinlostDate_TicketStatus] ON [dbo].[TpBetRecord]
GO

ALTER TABLE dbo.TpBetRecord
	ALTER COLUMN Stake DECIMAL(20, 4)
GO
ALTER TABLE dbo.TpBetRecord
	ALTER COLUMN WinlostAmount DECIMAL(20, 4)
GO
ALTER TABLE dbo.TpBetRecord
	ALTER COLUMN ValidBet DECIMAL(20, 4)
GO

CREATE NONCLUSTERED INDEX [IX_WinlostDate_TicketStatus] ON [dbo].[TpBetRecord]
(
	[WinlostDate] ASC,
	[TicketStatus] ASC
)
INCLUDE ( 	[Stake],
	[ValidBet],
	[WinlostAmount],
	[Revenue],
	[CustId],
	[UserName],
	[CurrencyId],
	[SiteId],
	[TransTime],
	[SettledTime],
	[BonusId],
	[SettlementType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
GO

------------
ALTER TABLE dbo.N88_SumWinloss
	ADD Revenue MONEY
GO

-- Include new column Revenue into Index IX_TransTime
DROP INDEX [IX_TransTime] ON [dbo].[N88_SumWinloss]
GO

CREATE NONCLUSTERED INDEX [IX_TransTime] ON [dbo].[N88_SumWinloss]
(
	[TransTime] ASC
)
INCLUDE ( 	[GameType],
	[Currency],
	[TurnOver],
	[ValidBet],
	[Winloss],
	[Revenue],
	[BetCount],
	[StatusId],
	[UserName],
	[IsTest]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON PS_N88_SumWinloss_Monthly
GO
