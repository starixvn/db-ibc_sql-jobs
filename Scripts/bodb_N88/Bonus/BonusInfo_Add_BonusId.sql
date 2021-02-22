/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210205@Percy
	DB: DBN88-bodb_N88
	Task: Bonus Report Phase 2 - Add BonusId into TpBetRecord
*/

USE bodb_N88
GO

ALTER TABLE dbo.TpBetRecord
	ADD BonusId INT
GO

-- Include BonusId, SettlementType into index IX_WinlostDate_TicketStatus
DROP INDEX [IX_WinlostDate_TicketStatus] ON [dbo].[TpBetRecord]
GO

CREATE NONCLUSTERED INDEX [IX_WinlostDate_TicketStatus] ON [dbo].[TpBetRecord]
(
	[WinlostDate] ASC,
	[TicketStatus] ASC
)
INCLUDE ( 	[Stake],
	[WinlostAmount],
	[CustId],
	[UserName],
	[CurrencyId],
	[SiteId],
	[TransTime],
	[SettledTime],
	[BonusId],
	[SettlementType]) ON [ReportData]
GO