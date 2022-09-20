/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: Helen@20220912
	DB: DBSIG.BODB02
	Task: 
	Revision:
		- 20220912@Helen: scaleout project [176932]
*/
USE bodb02
GO
CREATE TABLE [dbo].[BalanceTrigger](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[custid] [int] NOT NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[actual_stake] [money] NOT NULL,
	[winlost] [money] NOT NULL,
	[playercomm] [money] NOT NULL,
	[BalanceChanged] [money] NOT NULL,
	[NewBalance] [money] NULL,
	[ActionDate] [datetime] NOT NULL,
	[ActionID] [tinyint] NULL,
	[Action] [varchar](200) NOT NULL,
	[BTBalance] [money] NULL,
	[StatusId] [tinyint] NULL,
	[MatchId] [int] NULL,
	[SettlementType] [tinyint] NULL CONSTRAINT [DF_BalanceTrigger_SettlementType]  DEFAULT ((0)),
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[modds] [smallmoney] NULL
	--[RepUpdateTime] [datetime2](7) NULL CONSTRAINT [DF_BalanceTrigger_RepUpdateTime]  DEFAULT (SYSDATETIME()),
 CONSTRAINT [PK_BalanceTrigger] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [BALANCE]
) ON [BALANCE]

GO

--CREATE NONCLUSTERED INDEX [IX_RepUpdateTime] ON [dbo].[BalanceTrigger]
--(
--	[RepUpdateTime] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [BALANCE]
--GO