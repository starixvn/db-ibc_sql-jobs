/*
	Created: 20180615@Winnie
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DBCHECK/CheckResultDB

	Revisions:
		- 20201116@Tina: check exists before create new table, deploy for feature store site at member level [Redmind: #144323]
*/

USE [CheckResultDB]
GO
IF OBJECT_ID('[dbo].[CheckCustInfoResult]') IS NULL
BEGIN
	CREATE TABLE [dbo].[CheckCustInfoResult](
		[RuleID] [int] NOT NULL,
		[CustID] [int] NULL,
		[CreatedDate] [datetime] NULL
	) ON [CheckResultData]
END
GO

IF  OBJECT_ID('[DF_CheckRecommendRule_CreatedDate]','D') IS NULL
BEGIN
	ALTER TABLE [dbo].[CheckCustInfoResult] ADD  CONSTRAINT [DF_CheckRecommendRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'RuleName'
          AND Object_ID = Object_ID(N'[dbo].[Rule_Credit]'))
BEGIN
    ALTER TABLE Rule_Credit ALTER COLUMN RuleName VARCHAR(200) NULL; 
END
 
GO



