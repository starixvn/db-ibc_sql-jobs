/*
	Created: 20190909@Johnson
	Task: cn88 structure for checking data 
	DB: DBCHECK-CheckResultDB
*/

USE [CheckResultDB]
GO

DROP TABLE CS_CheckBetLimitResult
GO

CREATE TABLE [dbo].[CS_CheckBetLimitResult](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[IsLive] [bit] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [money] NULL,
	[ValueB] [money] NULL,	
	[CreatedDate] [datetime] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CS_CheckBetLimitResult] ADD  CONSTRAINT [DF_CS_CheckBetLimitRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[CS_CheckBetLimitResult] ADD  DEFAULT ((0)) FOR [IsLive]
GO

CREATE CLUSTERED INDEX [CIX_CS_CheckBetLimitResult] ON [dbo].[CS_CheckBetLimitResult] 
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CS_CheckBetLimitResult_CreatedDate] ON [dbo].[CS_CheckBetLimitResult] 
(
	[CreatedDate] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO