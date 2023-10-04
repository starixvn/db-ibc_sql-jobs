/*<info serverAlias="DBCTG-bodb02,DBSIC-bodb02"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalanceCust
	DB: DBCTG-bodb02,DBSIC-bodb02
	Remark: Run on credit site only
*/
USE [bodb02]
GO

-- [Age_ClearBalanceCust_BatchLog]
CREATE TABLE [dbo].[Age_ClearBalanceCust_BatchLog](
	[BatchLogId] [int] IDENTITY(1,1) NOT NULL,
	[SuperId] [int] NOT NULL,
	[BatchNo] [int] NOT NULL,
	[Command] [varchar](MAX),
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[BatchStatus] [varchar](15),
	[RunningMode] [varchar](15),
	CONSTRAINT [PK_Age_ClearBalanceCust_BatchLog] PRIMARY KEY CLUSTERED 
	(
		[BatchLogId] ASC
	)
) ON [Others_table]
GO
CREATE NONCLUSTERED INDEX IX_SuperBatch ON dbo.[Age_ClearBalanceCust_BatchLog]([SuperId], [BatchNo]) ON [Others_table]
GO 

--[Age_ClearBalanceCust_Process]
CREATE TABLE [dbo].[Age_ClearBalanceCust_Process](
	[SessionDate] [smalldatetime] NOT NULL,
	[BatchNo] [int] NOT NULL,
	[SuperId] [int] NOT NULL,
	[FromCustId] [int] NOT NULL,
	[ToCustId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
	[Status] [varchar](15) NOT NULL,
	[Amount] [money] NULL,
	[Result] [nvarchar](MAX) NULL,
	[TryCount] [tinyint] NULL,
	[ModifiedTime] [datetime] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Creator] [int] NULL,
	[IsAllDayBalTransfer] [bit] NULL,
	CONSTRAINT [PK_Age_ClearBalanceCust_Process] PRIMARY KEY NONCLUSTERED 
	(
		[FromCustId] ASC,
		[ToCustId] ASC
	)
) ON [Others_table]
GO
CREATE CLUSTERED INDEX CIX_SuperBatch ON dbo.[Age_ClearBalanceCust_Process]([SuperId], [BatchNo]) ON [Others_table]
GO

--[Age_ClearBalanceCust_RunningSuper]
CREATE TABLE [dbo].[Age_ClearBalanceCust_RunningSuper](
	[SuperId] [int] NOT NULL,
	[TotalBatch] [int] NULL,
	[RunningTotal] [int] NULL,
	[RunningBatchNo] [int] NULL,
	[TotalDownline] [int] NULL,
	CONSTRAINT [PK_Age_ClearBalanceCust_RunningSuper] PRIMARY KEY CLUSTERED 
	(
		[SuperId] ASC
	)
) ON [Others_table]
GO


