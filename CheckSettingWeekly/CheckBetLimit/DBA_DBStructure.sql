/*
	Created: 20170407@Helen
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/

USE [CheckResultDB]
GO

DROP TABLE [CheckBetLimitResult]
GO
DROP TABLE CheckBetLimitResult_DCS
GO

CREATE TABLE [dbo].[CheckBetLimitResult](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [money] NULL,
	[ValueB] [money] NULL,
	[CreatedDate] [datetime] NULL,
	IsDeposit BIT NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckBetLimitResult] ADD  CONSTRAINT [DF_CheckBetLimitResult_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE TABLE [dbo].[CheckBetLimitResult_DCS](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [money] NULL,
	[ValueB] [money] NULL,
	[CreatedDate] [datetime] NULL,
	IsDeposit BIT NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckBetLimitResult_DCS] ADD  CONSTRAINT [DF_CheckBetLimitResult_DCSRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO




