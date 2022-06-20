/*<info serverAlias="DBBAH-BalanceRecord"></info>*/
/*
	Created: 20220620@Sol
	Task: Database Improvement - New BalanceRecord_ReOrder - [Redmine:172094]
	Database: DBBAH-BalanceRecord
*/

USE [BalanceRecord]

GO

CREATE TABLE [dbo].BalanceRecord_ReOrder(
	[RowID] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NULL,
	[actual_stake] [money] NULL,
	[winlost] [money] NULL,
	[playercomm] [money] NULL,
	[BalanceChanged] [money] NOT NULL,
	[NewBalance] [money] NULL,
	[ActionDate] [datetime] NOT NULL,
	[ActionID] [tinyint] NULL,
	[Action] [varchar](200) NOT NULL,
	[BTBalance] [money] NULL,
	[StatusId] [tinyint] NULL,
	[MatchId] [int] NULL,
	[SettlementType] [tinyint] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[modds] [smallmoney] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].BalanceRecord_ReOrder ADD  CONSTRAINT [DF_BalanceRecord_ReOrder_SettlementType]  DEFAULT ((0)) FOR [SettlementType]

GO

CREATE CLUSTERED INDEX [CIX_custid_actiondate] ON [dbo].BalanceRecord_ReOrder
(
	[custid] ASC,
	[ActionDate] ASC
) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [IX_ActionID] ON [dbo].BalanceRecord_ReOrder
(
	[ActionID] ASC
)
INCLUDE([custid],[ActionDate],[Action]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_BalanceRecord_ReOrder_MatchId] ON [dbo].BalanceRecord_ReOrder
(
	[MatchId] ASC
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_RowID] ON [dbo].BalanceRecord_ReOrder
(
	[RowID] ASC
) ON [PRIMARY]
GO