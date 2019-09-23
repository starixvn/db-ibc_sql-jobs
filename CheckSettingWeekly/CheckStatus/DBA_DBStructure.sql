/*
	Created: 20170407@Helen
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/

USE [CheckResultDB]
GO

DROP TABLE [CheckStatusResult]
GO
DROP TABLE CheckStatusResult_DCS
GO

CREATE TABLE [dbo].[CheckStatusResult](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [BIT] NULL,
	[ValueB] [BIT] NULL,
	[CreatedDate] [datetime] NULL,
	IsDeposit BIT NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckStatusResult] ADD  CONSTRAINT [DF_CheckStatusRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE TABLE [dbo].[CheckStatusResult_DCS](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [BIT] NULL,
	[ValueB] [BIT] NULL,
	[CreatedDate] [datetime] NULL,
	IsDeposit BIT NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckStatusResult_DCS] ADD  CONSTRAINT [DF_CheckStatusDCSRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO




