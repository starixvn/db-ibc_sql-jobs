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
