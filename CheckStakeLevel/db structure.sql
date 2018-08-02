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


INSERT INTO [CheckResultDB].[dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 301,'Missing stake level setting', GETDATE()	
UNION SELECT 302,'stake level super <> global setting'	, GETDATE()
UNION SELECT 303,'stake level master not exist in super', GETDATE()	
UNION SELECT 304,'stake level agent not exist in master', GETDATE()	
UNION SELECT 305,'stake level member not exist in agent', GETDATE()	


