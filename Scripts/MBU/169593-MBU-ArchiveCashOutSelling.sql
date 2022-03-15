/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20220309@Max
	Task: MBU - Copy data of Cash Out Selling to bk table [Redmine: #169593]
	DB: DBARC/bodb_Archive

	Notes:
*/

USE [bodb_Archive]
GO

CREATE TABLE [dbo].[CashOutSelling_bk](
	[TransID] [bigint] NOT NULL,
	[MatchID] [int] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[Custid] [int] NOT NULL,
	[CashOutStatus] [tinyint] NOT NULL,
	[Winlost] [money] NOT NULL,
	[PriceInfo] [varchar](1000) NULL,
	[CheckTime] [datetime] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[ChangeDate] [datetime] NOT NULL,
	[VirtualRate] [float] NOT NULL,
	[CashoutExtraInfo] [varchar](2000) NULL,
 CONSTRAINT [PK_CashOutSelling_bk] PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

ALTER TABLE [dbo].[CashOutSelling_bk] ADD  CONSTRAINT [DF_CashOutSelling_bk_CashOutStatus]  DEFAULT ((0)) FOR [CashOutStatus]
GO

ALTER TABLE [dbo].[CashOutSelling_bk] ADD  CONSTRAINT [DF_CashOutSelling_bk_Winlost]  DEFAULT ((0)) FOR [Winlost]
GO

ALTER TABLE [dbo].[CashOutSelling_bk] ADD  CONSTRAINT [DF_CashOutSelling_bk_CheckTime]  DEFAULT (getdate()) FOR [CheckTime]
GO

ALTER TABLE [dbo].[CashOutSelling_bk] ADD  CONSTRAINT [DF_CashOutSelling_bk_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[CashOutSelling_bk] ADD  CONSTRAINT [DF_CashOutSelling_bk_VirtualRate]  DEFAULT ((0)) FOR [VirtualRate]
GO




