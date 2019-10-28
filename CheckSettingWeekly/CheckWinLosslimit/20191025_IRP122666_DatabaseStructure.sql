/*
	Created: 20191025@Johnson
	Task: structure for checking win loss limit
	DB: DBCHECK-CheckResultDB
*/


USE [CheckResultDB]
GO

CREATE TABLE [dbo].[CheckWinLossLimitResult_Credit](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [smallmoney] NULL,
	[ValueB] [smallmoney] NULL,
	[CreatedDate] [datetime] NULL,
	[IsLive] [bit] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckWinLossLimitResult_Credit] ADD  CONSTRAINT [DF_CheckWinLossLimitResult_Credit_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[CheckWinLossLimitResult_Credit] ADD  DEFAULT ((0)) FOR [IsLive]
GO

CREATE CLUSTERED INDEX [CIX_CheckWinLossLimitResult_Credit] ON [dbo].[CheckWinLossLimitResult_Credit] 
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO