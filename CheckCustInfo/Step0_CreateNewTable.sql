/*
	Created: 20180615@Winnie
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/

USE [CheckResultDB]
GO
CREATE TABLE [dbo].[CheckCustInfoResult](
	[RuleID] [int] NOT NULL,
	[CustID] [int] NULL,
	[CreatedDate] [datetime] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckCustInfoResult] ADD  CONSTRAINT [DF_CheckRecommendRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO


