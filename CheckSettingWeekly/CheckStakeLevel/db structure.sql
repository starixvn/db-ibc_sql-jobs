/*
	Created: Johnson
	Date: 2018-07-27
	Task: prepare structure for CheckResultStakeLevel_Credit
	DB: DBCHECK.CheckResultDB
*/

USE [CheckResultDB]
GO

CREATE TABLE [dbo].[CheckResultStakeLevel_Credit](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] VARCHAR(100) NULL,
	[ValueB] VARCHAR(100) NULL,
	[CreatedDate] [datetime] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckResultStakeLevel_Credit] ADD  CONSTRAINT [DF_CheckResultStakeLevel_Credit_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE CLUSTERED INDEX [CIX_CheckResultStakeLevel_Credit] ON [dbo].[CheckResultStakeLevel_Credit]
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CheckResultStakeLevel_Credit_CreatedDate] ON [dbo].[CheckResultStakeLevel_Credit]
(
	[CreatedDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO


CREATE TABLE [dbo].[CheckResultStakeLevel_Deposit](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] VARCHAR(100) NULL,
	[ValueB] VARCHAR(100) NULL,
	[CreatedDate] [datetime] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckResultStakeLevel_Deposit] ADD  CONSTRAINT [DF_CheckResultStakeLevel_Deposit_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO


CREATE CLUSTERED INDEX [CIX_CheckResultStakeLevel_Deposit] ON [dbo].[CheckResultStakeLevel_Deposit]
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CheckResultStakeLevel_Deposit_CreatedDate] ON [dbo].[CheckResultStakeLevel_Deposit]
(
	[CreatedDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
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

CREATE CLUSTERED INDEX [CIX_CheckBetLimitResult] ON [dbo].[CheckBetLimitResult]
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CheckBetLimitResult_CreatedDate] ON [dbo].[CheckBetLimitResult]
(
	[CreatedDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
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

ALTER TABLE [dbo].[CheckBetLimitResult_DCS] ADD  CONSTRAINT [DF_CheckBetLimitResult_DCS_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE CLUSTERED INDEX [CIX_CheckBetLimitResult_DCS] ON [dbo].[CheckBetLimitResult_DCS]
(
	[RuleId] ASC,
	[SportType] ASC,
	[BetType] ASC,
	[CustIdA] ASC,
	[CustIdB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO

CREATE NONCLUSTERED INDEX [IX_CheckBetLimitResult_DCS_CreatedDate] ON [dbo].[CheckBetLimitResult_DCS]
(
	[CreatedDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
GO

INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 301,'Missing stake level setting', GETDATE()	
UNION SELECT 302,'stake level super <> global setting'	, GETDATE()
UNION SELECT 303,'stake level master not exist in super', GETDATE()	
UNION SELECT 304,'stake level agent not exist in master', GETDATE()	
UNION SELECT 305,'stake level member not exist in agent', GETDATE()	
UNION SELECT 311,'min bet > max bet', GETDATE()	
UNION SELECT 312,'max bet > max per match', GETDATE()	
UNION SELECT 313,'Missing bet limit setting', GETDATE()	
UNION SELECT 314,'minbet < 0', GETDATE()	
UNION SELECT 315,'maxbet < 0', GETDATE()	
UNION SELECT 316,'max per match < 0', GETDATE()	

