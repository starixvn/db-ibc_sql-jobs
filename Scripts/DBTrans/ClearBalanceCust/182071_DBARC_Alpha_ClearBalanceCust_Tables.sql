/*<info serverAlias="DBARC-bodb_Archive"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalanceCust
	DB: DBARC.bodb_Archive
	Remark: 
*/
USE [bodb_Archive]
GO

CREATE TABLE [dbo].[Age_ClearBalanceCust_ProcessHistory](
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
	[IsAllDayBalTransfer] [bit] NULL
) ON [DATA] 
GO

CREATE CLUSTERED INDEX CIX_SessionDate ON dbo.[Age_ClearBalanceCust_ProcessHistory]([SessionDate], [FromCustId]) ON [DATA];
GO