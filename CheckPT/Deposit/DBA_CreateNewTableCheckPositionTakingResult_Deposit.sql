USE [CheckResultDB]
GO

/*  
	Created: 20180828@Winnie
	Task: Create new table CheckPositionTakingResult_Deposit
	DB: DBCHECK/CheckResultDB  

*/  


CREATE TABLE [dbo].[CheckPositionTakingResult_Deposit](
	[RuleId] [smallint] NULL,
	[SportType] [smallint] NULL,
	[BetType] [smallint] NULL,
	[CustIdA] [int] NULL,
	[CustIdB] [int] NULL,
	[ValueA] [smallmoney] NULL,
	[ValueB] [smallmoney] NULL,
	[CreatedDate] [datetime] NULL CONSTRAINT [DF_CheckPositionTakingResultDeposit_CreatedDate]  DEFAULT (getdate()),
	[IsLive] [bit] NULL DEFAULT ((0))
) ON [CheckResultData]

GO


