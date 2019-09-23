/*  
	Created: 20180815@Winnie
	Task: Insert rules to check commission deposit and create new table CheckCommissionResult_Deposit
	DB: DBCHECK/CheckResultDB  

*/  

USE [CheckResultDB]
GO

CREATE TABLE [dbo].[CheckCommissionResult_Deposit](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,	
	[ValueA] [smallmoney] NULL,
	[ValueB] [smallmoney] NULL,
	[CreatedDate] [datetime] NULL
) ON [CheckResultData]

GO

ALTER TABLE [dbo].[CheckCommissionResult_Deposit] ADD  CONSTRAINT [DF_CheckCommDepRule_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO


INSERT INTO [dbo].[Rule_Credit]
           ([RuleId]
           ,[RuleName]
           ,[ModifiedDate])
SELECT 110,'Missing setting in Dep_CustCommRate, Dep_AgentCommRate (Colosusbet)',GETDATE()
UNION
SELECT 111,'Dep_CustCommRate.playerdiscount <> 0',GETDATE()
UNION
SELECT 112,'Dep_CustCommRate.sdiscount <> adiscount <> discount',GETDATE()
UNION
SELECT 113,'Dep_AgentCommRate.comRate <> 0.1215 (Colosusbets bettype 18001)',GETDATE()
UNION
SELECT 114,'Dep_AgentCommRate.comRate <> 0.45 (CB bettype 18002)',GETDATE()
UNION
SELECT 115,'BetTradeComm.HouseDeductionRate <> 0.015',GETDATE()
UNION
SELECT 116,'BetTradeComm.bettradecomm <> 0.04',GETDATE()
UNION
SELECT 117,'BetTradeComm.Licenseecomm <> 0.03 (isBA=0)',GETDATE()
UNION
SELECT 118,'BetTradeComm.Licenseecomm <> 0 (isBA=1)',GETDATE()

