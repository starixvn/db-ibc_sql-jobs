/*
	Created: 20190718@Johnson
	Task: cn88 structure for checking data 
	DB: DBCHECK-CheckResultDB
*/

USE [CheckResultDB]
GO

CREATE TABLE [dbo].[CS_CheckPTResult](
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

ALTER TABLE [dbo].[CS_CheckPTResult] ADD  CONSTRAINT [DF_CS_CheckPTRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[CS_CheckPTResult] ADD  DEFAULT ((0)) FOR [IsLive]
GO

CREATE CLUSTERED INDEX [CIX_CS_CheckPTResult] ON [dbo].[CS_CheckPTResult] 
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CS_CheckPTResult_CreatedDate] ON [dbo].[CS_CheckPTResult] 
(
	[CreatedDate] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO


CREATE TABLE [dbo].[CS_CheckCommResult](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [smallmoney] NULL,
	[ValueB] [smallmoney] NULL,
	[GroupID] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[IsLive] [bit] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CS_CheckCommResult] ADD  CONSTRAINT [DF_CS_CheckCommRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[CS_CheckCommResult] ADD  DEFAULT ((0)) FOR [IsLive]
GO

CREATE CLUSTERED INDEX [CIX_CS_CheckCommResult] ON [dbo].[CS_CheckCommResult] 
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CS_CheckCommResult_CreatedDate] ON [dbo].[CS_CheckCommResult] 
(
	[CreatedDate] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultData]
GO

CREATE TABLE [dbo].[CS_CheckBetLimitResult](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[IsLive] [bit] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [smallmoney] NULL,
	[ValueB] [smallmoney] NULL,	
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

CREATE TABLE [dbo].[CS_Supers](
	[CustId] [int] NOT NULL,
	[PT] [tinyint] NULL,	
	[Comm] [tinyint] NULL,	
	[BetLimit] [tinyint] NULL
 CONSTRAINT [PK_CS_Supers] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CheckResultTable]
) ON [CheckResultTable]

GO

ALTER TABLE [dbo].[CS_Supers] ADD  CONSTRAINT [DF_CS_Supers_PT]  DEFAULT ((0)) FOR [PT]
GO

ALTER TABLE [dbo].[CS_Supers] ADD  CONSTRAINT [DF_CS_Supers_Comm]  DEFAULT ((0)) FOR [Comm]
GO

ALTER TABLE [dbo].[CS_Supers] ADD  CONSTRAINT [DF_CS_Supers_BetLimit]  DEFAULT ((0)) FOR [BetLimit]
GO
