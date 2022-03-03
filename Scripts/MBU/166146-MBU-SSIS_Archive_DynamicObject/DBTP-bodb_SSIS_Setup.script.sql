/*<info serverAlias="DBTP-SSISDB"></info>*/
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP.SSISDB
*/
USE [SSISDB]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](100) NULL,
	[SourceServer] [varchar](100) NULL,
	[SourceDB] [varchar](100) NULL,
	[ExecCommand] [varchar](1000) NULL,
	[CommandType] [varchar](50) NULL,
	[BatchSize] [int] NULL,
	[ChunkSize] [int] NULL,
	[Active] [bit] NULL,
	[OutputFileInfo] [varchar](100) NULL,
	[SyncParallel] [bit] NULL,
	[IsCanceled] bit default(0),
 CONSTRAINT [PK_SSIS_DynamicMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_OutputFile]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_OutputFile](
	[FileID] [int] IDENTITY(1,1) NOT NULL,
	[RuntimeID] [int] NULL,
	[DynamicMappingID] [int] NULL,
	[FileName] [varchar](1000) NULL,
	[RowTotal] [int] NULL,
	[ARC_Status] [bit] NULL,
	[HA_Status] [bit] NULL,
	[DR_Status] [bit] NULL,
	[CreateTime] [datetime] NULL,
 CONSTRAINT [PK_SSIS_DynamicMapping_OutputFile] PRIMARY KEY CLUSTERED 
(
	[FileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Package]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Package](
	[DynamicMappingID] [int] NOT NULL,
	[PackageID] [int] NOT NULL,
	[GrantMode] varchar(15) default('Normal'),
 CONSTRAINT [PK_SSIS_DynamicMapping_Package] PRIMARY KEY CLUSTERED 
(
	[DynamicMappingID] ASC,
	[PackageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Param]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Param](
	[DynamicMappingID] [int] NULL,
	[ParamName] [varchar](50) NULL,
	[ParamType] [varchar](50) NULL,
	[ParamDesc] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_DynamicMapping_Target]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_DynamicMapping_Target](
	[TargetID] [int] IDENTITY(1,1) NOT NULL,
	[DynamicMappingID] [int] NOT NULL,
	[TargetTable] [varchar](100) NOT NULL,
	[TargetServer] [varchar](100) NOT NULL,
	[TargetDB] [varchar](100) NULL,
	[Active] [bit] NULL,
	[Environment] [varchar](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package](
	[PackageID] [int] IDENTITY(1,1) NOT NULL,
	[PackageName] [varchar](100) NULL,
 CONSTRAINT [PK_SSIS_Package] PRIMARY KEY CLUSTERED 
(
	[PackageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package_ENV]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package_ENV](
	[PackageID] [int] NULL,
	[Environment] [varchar](50) NULL,
	[Active] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_Package_Param]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_Package_Param](
	[PackageID] [int] NOT NULL,
	[ParamName] [varchar](50) NOT NULL,
	[ParamType] [varchar](50) NULL,
 CONSTRAINT [PK_SSIS_Package_Param] PRIMARY KEY CLUSTERED 
(
	[PackageID] ASC,
	[ParamName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_PackageRuntime]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_PackageRuntime](
	[RuntimeID] [int] IDENTITY(1,1) NOT NULL,
	[PackageID] [int] NOT NULL,
	[DynamicMappingID] [int] NULL,
	[Environment] [varchar](10) NULL,
	[Command] [varchar](250) NULL,
	[TargetInfo] [varchar](1000) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Status] [varchar](10) NULL,
	[Error] [varchar](250) NULL,
	[Creator] [varchar](50) NULL,
	[ParentID] [int] NULL,
	[Message] [varchar](250) NULL,
	[RowTotal] [int] NULL,
	[SessionID] [varchar](50) NULL,
 CONSTRAINT [PK_SSIS_PackageRuntime] PRIMARY KEY CLUSTERED 
(
	[RuntimeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SSIS_PackageRuntime_Param]    Script Date: 2/17/2022 1:14:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SSIS_PackageRuntime_Param](
	[RuntimeID] [int] NOT NULL,
	[ParamName] [varchar](100) NOT NULL,
	[ParamValue] [varchar](100) NULL
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[SSIS_DynamicMapping] ON 
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (1, N'sum_winloss', N'DBTRANS', N'bodb02', N'dbo.SSIS_Sum_Winloss_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (2, N'BetStatement', N'DBTRANS', N'bodb02', N'dbo.SSIS_BetStatement_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (3, N'Statement', N'DBTRANS', N'bodb02', N'dbo.SSIS_Statement_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (4, N'Transfer', N'DBTRANS', N'bodb02', N'dbo.SSIS_Transfer_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (5, N'bettransLC14', N'DBTRANS', N'bodb02', N'dbo.SSIS_BettransLC14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (6, N'bettransRnG14', N'DBTRANS', N'bodb02', N'dbo.SSIS_BettransRNG14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (7, N'translog14', N'DBTRANS', N'bodb02', N'dbo.SSIS_Translog14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (8, N'bettransG14', N'DBTRANS', N'bodb02', N'dbo.SSIS_bettransG14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (9, N'bettransm14', N'DBTRANS', N'bodb02', N'dbo.SSIS_bettransm14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (10, N'SettlementNG2_Message', N'DBTRANS', N'bodb02', N'dbo.SSIS_SettlementNG2_Message_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (11, N'bettrans_Staging', N'DBTRANS', N'bodb02', N'dbo.SSIS_bettrans_Staging_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (12, N'transfer_fi', N'DBTRANS', N'bodb02', N'dbo.SSIS_Transfer_fi_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (13, N'Transfer_Coll', N'DBTRANS', N'bodb02', N'dbo.SSIS_Transfer_Coll_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (14, N'bettrans14', N'DBTRANS', N'bodb02', N'dbo.SSIS_Bettrans14_Export', N'SP', 10000, 200000, 1, N'', 1)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (15, N'BetParlayResult', N'DBTRANS', N'bodb02', N'dbo.SSIS_BetParlayResult_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (16, N'TicketVoiding_RequestDetail', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_RequestDetail_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (17, N'TicketVoiding_Request', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_Request_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (18, N'TicketVoiding_AutoVoidRequest_Queue', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_AutoVoidRequest_Queue_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (19, N'TicketVoiding_AutoUnmarkSetting', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_AutoUnmarkSetting_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (20, N'TicketVoiding_OperatorInfo', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_OperatorInfo_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (21, N'TicketVoiding_Queue', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_Queue_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (22, N'TicketVoiding_VoidingHistory', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_VoidingHistory_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (23, N'TicketVoiding_RequestDetailTicket_Single', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_RequestDetailTicket_Single_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (24, N'TicketVoiding_RequestDetailTicket_SubParlay', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_RequestDetailTicket_SubParlay_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (25, N'TicketVoiding_Reason', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_Reason_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (26, N'zzzbettransM', N'DBTRANS', N'bodb02', N'dbo.SSIS_zzzbettransM_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (27, N'TicketVoiding_VoidedTransaction', N'DBTRANS', N'bodb02', N'dbo.SSIS_TicketVoiding_VoidedTransaction_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (28, N'zzzbettrans', N'DBTRANS', N'bodb02', N'dbo.SSIS_zzzbettrans_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (29, N'odds14', N'DBPRO', N'bodb02', N'dbo.SSIS_odds14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (30, N'match14', N'DBPRO', N'bodb02', N'dbo.SSIS_match14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (31, N'bingoBall14', N'DBPRO', N'bodb02', N'dbo.SSIS_bingoBall14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (32, N'outright14', N'DBPRO', N'bodb02', N'dbo.SSIS_outright14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (33, N'VSOutright14', N'DBPRO', N'bodb02', N'dbo.SSIS_VSOutright14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (34, N'match_remark', N'DBPRO', N'bodb02', N'dbo.SSIS_match_remark_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (35, N'MatchMaxbet14', N'DBPRO', N'bodb02', N'dbo.SSIS_MatchMaxbet14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (36, N'ResultDetail14', N'DBPRO', N'bodb02', N'dbo.SSIS_ResultDetail14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (37, N'ResultDetail3rd14', N'DBPRO', N'bodb02', N'dbo.SSIS_ResultDetail3rd14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (38, N'EventInfo3rd14', N'DBPRO', N'bodb02', N'dbo.SSIS_EventInfo3rd14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (39, N'AutoPayoutResult14', N'DBPRO', N'bodb02', N'dbo.SSIS_AutoPayoutResult14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (40, N'ProviderResultDetail14', N'DBPRO', N'bodb02', N'dbo.SSIS_ProviderResultDetail14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (41, N'Odds3rd14', N'DBPRO', N'bodb02', N'dbo.SSIS_Odds3rd14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (42, N'Intg_OddsFeed_SettlementAction14', N'DBPRO', N'bodb02', N'dbo.SSIS_Intg_OddsFeed_SettlementAction_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (43, N'Intg_OddsFeed_SettlementAction_Outright14', N'DBPRO', N'bodb02', N'dbo.SSIS_Intg_OddsFeed_SettlementAction_Outright_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (44, N'Match3rd14', N'DBPRO', N'bodb02', N'dbo.SSIS_Match3rd14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (45, N'oddsES14', N'DBPRO', N'bodb02', N'dbo.SSIS_oddsES14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (46, N'ResultDetailES14', N'DBPRO', N'bodb02', N'dbo.SSIS_ResultDetailES14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (47, N'SMP_Market14', N'DBPRO', N'bodb02', N'dbo.SSIS_SMP_Market14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (48, N'SMP_MarketSelection14', N'DBPRO', N'bodb02', N'dbo.SSIS_SMP_MarketSelection14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (49, N'Dot_Admin_Assignment_Trader14', N'DBPRO', N'bodb02', N'dbo.SSIS_Dot_Admin_Assignment_Trader_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (50, N'oddsOS14', N'DBPRO', N'bodb02', N'dbo.SSIS_oddsOS14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (51, N'ResultDetailOS14', N'DBPRO', N'bodb02', N'dbo.SSIS_ResultDetailOS14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (52, N'VSRaceInfo14', N'DBPRO', N'bodb02', N'dbo.SSIS_VSRaceInfo14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (53, N'ProviderExternalResultDetailES14', N'DBPRO', N'bodb02', N'dbo.SSIS_ProviderExternalResultDetailES14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (54, N'ProviderExternalResultDetailOS14', N'DBPRO', N'bodb02', N'dbo.SSIS_ProviderExternalResultDetailOS14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (55, N'ProviderExternalResultDetail14', N'DBPRO', N'bodb02', N'dbo.SSIS_ProviderExternalResultDetail14_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (56, N'AutoRefundResult14', N'DBPRO', N'bodb02', N'dbo.SSIS_AutoRefundResult_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping] ([ID], [TableName], [SourceServer], [SourceDB], [ExecCommand], [CommandType], [BatchSize], [ChunkSize], [Active], [OutputFileInfo], [SyncParallel]) VALUES (57, N'TOControl_Setting', N'DBCUST', N'CustDB', N'dbo.SSIS_TOControl_Setting_Export', N'SP', 5000, 2000000, 0, N'csv', NULL)
GO
SET IDENTITY_INSERT [dbo].[SSIS_DynamicMapping] OFF
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (1, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (2, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (3, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (4, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (5, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (6, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (7, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (8, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (9, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (10, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (11, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (12, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (13, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (14, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (15, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (16, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (17, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (18, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (19, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (20, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (21, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (22, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (23, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (24, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (25, 4)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (26, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (27, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (28, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (29, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (30, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (31, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (32, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (33, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (34, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (35, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (36, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (37, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (38, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (39, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (40, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (41, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (42, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (43, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (44, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (45, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (46, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (47, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (48, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (49, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (50, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (51, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (52, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (53, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (54, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (55, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (56, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Package] ([DynamicMappingID], [PackageID]) VALUES (57, 2)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (1, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (2, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (3, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (4, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (5, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (6, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (7, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (8, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (9, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (10, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (11, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (12, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (13, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (14, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (15, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (16, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (17, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (18, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (19, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (20, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (21, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (22, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (23, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (24, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (25, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (26, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (27, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (28, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (29, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (30, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (31, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (32, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (33, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (34, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (35, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (36, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (37, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (38, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (39, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (40, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (41, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (42, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (43, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (44, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (45, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (46, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (47, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (48, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (49, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (50, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (51, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (52, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (53, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (54, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (55, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (56, N'winlostdate', N'smalldatetime', NULL)
GO
INSERT [dbo].[SSIS_DynamicMapping_Param] ([DynamicMappingID], [ParamName], [ParamType], [ParamDesc]) VALUES (57, N'winlostdate', N'smalldatetime', NULL)
GO
SET IDENTITY_INSERT [dbo].[SSIS_DynamicMapping_Target] ON 
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (1, 1, N'sum_winloss_old', N'DB052', N'bodb_Summary', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (2, 2, N'Statement', N'DB061', N'bodb_report', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (3, 3, N'Statement', N'DB061', N'bodb_report', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (4, 4, N'transfer_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (5, 5, N'bettransLC_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (6, 6, N'bettransRnG_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (7, 7, N'translog_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (8, 8, N'bettransG', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (9, 9, N'bettransm', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (10, 10, N'SettlementNG2_Message_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (11, 11, N'bettrans_Staging_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (12, 12, N'transfer_fi', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (13, 13, N'Transfer_Coll_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (14, 14, N'bettrans_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (15, 15, N'BetParlayResult', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (16, 16, N'TicketVoiding_RequestDetail_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (17, 17, N'TicketVoiding_Request_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (18, 18, N'TicketVoiding_AutoVoidRequest_Queue_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (19, 19, N'TicketVoiding_AutoUnmarkSetting_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (20, 20, N'TicketVoiding_OperatorInfo_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (21, 21, N'TicketVoiding_Queue_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (22, 22, N'TicketVoiding_VoidingHistory_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (23, 23, N'TicketVoiding_RequestDetailTicket_Single_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (24, 24, N'TicketVoiding_RequestDetailTicket_SubParlay_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (25, 25, N'TicketVoiding_Reason_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (26, 26, N'zzzbettransM_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (27, 27, N'TicketVoiding_VoidedTransaction_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (28, 28, N'zzzbettrans_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (29, 29, N'odds_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (30, 30, N'match_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (31, 31, N'bingoBall_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (32, 32, N'outright_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (33, 33, N'VSOutright_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (34, 34, N'match_remark', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (35, 35, N'MatchMaxbet_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (36, 36, N'ResultDetail_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (37, 37, N'ResultDetail3rd_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (38, 38, N'EventInfo3rd_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (39, 39, N'AutoPayoutResult_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (40, 40, N'ProviderResultDetail_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (41, 41, N'Odds3rd_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (42, 42, N'Intg_OddsFeed_SettlementAction_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (43, 43, N'Intg_OddsFeed_SettlementAction_Outright_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (44, 44, N'Match3rd_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (45, 45, N'oddsES_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (46, 46, N'ResultDetailES_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (47, 47, N'SMP_Market_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (48, 48, N'SMP_MarketSelection_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (49, 49, N'Dot_Admin_Assignment_Trader_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (50, 50, N'oddsOS_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (51, 51, N'ResultDetailOS_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (52, 52, N'VSRaceInfo_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (53, 53, N'ProviderExternalResultDetailES_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (54, 54, N'ProviderExternalResultDetailOS_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (55, 55, N'ProviderExternalResultDetail_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (56, 56, N'AutoRefundResult_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (57, 57, N'TOControl_Setting_bk', N'DB061', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (58, 1, N'sum_winloss_old', N'DB053', N'bodb_Summary', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (59, 2, N'Statement', N'DB062', N'bodb_report', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (60, 3, N'Statement', N'DB062', N'bodb_report', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (61, 4, N'transfer_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (62, 5, N'bettransLC_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (63, 6, N'bettransRnG_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (64, 7, N'translog_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (65, 8, N'bettransG', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (66, 9, N'bettransm', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (67, 10, N'SettlementNG2_Message_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (68, 11, N'bettrans_Staging_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (69, 12, N'transfer_fi', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (70, 13, N'Transfer_Coll_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (71, 14, N'bettrans_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (72, 15, N'BetParlayResult', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (73, 16, N'TicketVoiding_RequestDetail_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (74, 17, N'TicketVoiding_Request_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (75, 18, N'TicketVoiding_AutoVoidRequest_Queue_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (76, 19, N'TicketVoiding_AutoUnmarkSetting_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (77, 20, N'TicketVoiding_OperatorInfo_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (78, 21, N'TicketVoiding_Queue_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (79, 22, N'TicketVoiding_VoidingHistory_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (80, 23, N'TicketVoiding_RequestDetailTicket_Single_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (81, 24, N'TicketVoiding_RequestDetailTicket_SubParlay_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (82, 25, N'TicketVoiding_Reason_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (83, 26, N'zzzbettransM_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (84, 27, N'TicketVoiding_VoidedTransaction_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (85, 28, N'zzzbettrans_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (86, 29, N'odds_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (87, 30, N'match_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (88, 31, N'bingoBall_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (89, 32, N'outright_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (90, 33, N'VSOutright_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (91, 34, N'match_remark', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (92, 35, N'MatchMaxbet_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (93, 36, N'ResultDetail_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (94, 37, N'ResultDetail3rd_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (95, 38, N'EventInfo3rd_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (96, 39, N'AutoPayoutResult_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (97, 40, N'ProviderResultDetail_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (98, 41, N'Odds3rd_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (99, 42, N'Intg_OddsFeed_SettlementAction_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (100, 43, N'Intg_OddsFeed_SettlementAction_Outright_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (101, 44, N'Match3rd_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (102, 45, N'oddsES_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (103, 46, N'ResultDetailES_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (104, 47, N'SMP_Market_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (105, 48, N'SMP_MarketSelection_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (106, 49, N'Dot_Admin_Assignment_Trader_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (107, 50, N'oddsOS_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (108, 51, N'ResultDetailOS_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (109, 52, N'VSRaceInfo_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (110, 53, N'ProviderExternalResultDetailES_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (111, 54, N'ProviderExternalResultDetailOS_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (112, 55, N'ProviderExternalResultDetail_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (113, 56, N'AutoRefundResult_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
INSERT [dbo].[SSIS_DynamicMapping_Target] ([TargetID], [DynamicMappingID], [TargetTable], [TargetServer], [TargetDB], [Active], [Environment]) VALUES (114, 57, N'TOControl_Setting_bk', N'DB062', N'bodb_archive', 1, N'PROD')
GO
SET IDENTITY_INSERT [dbo].[SSIS_DynamicMapping_Target] OFF
GO
SET IDENTITY_INSERT [dbo].[SSIS_Package] ON 
GO
INSERT [dbo].[SSIS_Package] ([PackageID], [PackageName]) VALUES (1, N'ETL_Process_Main')
GO
INSERT [dbo].[SSIS_Package] ([PackageID], [PackageName]) VALUES (2, N'ETL_Dynamic_Mapping')
GO
INSERT [dbo].[SSIS_Package] ([PackageID], [PackageName]) VALUES (3, N'ETL_Dynamic_Mapping_Transfer')
GO
INSERT [dbo].[SSIS_Package] ([PackageID], [PackageName]) VALUES (4, N'ETL_Dynamic_Mapping_TVS')
GO
INSERT [dbo].[SSIS_Package] ([PackageID], [PackageName]) VALUES (5, N'ETL_Dynamic_Mapping_File')
GO
SET IDENTITY_INSERT [dbo].[SSIS_Package] OFF
GO
INSERT [dbo].[SSIS_Package_ENV] ([PackageID], [Environment], [Active]) VALUES (1, N'PROD', 1)
GO
INSERT [dbo].[SSIS_Package_ENV] ([PackageID], [Environment], [Active]) VALUES (2, N'PROD', 1)
GO
INSERT [dbo].[SSIS_Package_ENV] ([PackageID], [Environment], [Active]) VALUES (3, N'PROD', 1)
GO
INSERT [dbo].[SSIS_Package_ENV] ([PackageID], [Environment], [Active]) VALUES (4, N'PROD', 1)
GO
INSERT [dbo].[SSIS_Package_ENV] ([PackageID], [Environment], [Active]) VALUES (5, N'PROD', 1)
GO
INSERT [dbo].[SSIS_Package_Param] ([PackageID], [ParamName], [ParamType]) VALUES (2, N'winlostdate', N'smalldate')
GO
INSERT [dbo].[SSIS_Package_Param] ([PackageID], [ParamName], [ParamType]) VALUES (3, N'BUDate', N'smalldate')
GO
INSERT [dbo].[SSIS_Package_Param] ([PackageID], [ParamName], [ParamType]) VALUES (4, N'winlostdate', N'smalldate')
GO
ALTER TABLE [dbo].[SSIS_DynamicMapping] ADD  CONSTRAINT [DF_SSIS_DynamicMapping_SyncParallel]  DEFAULT ((0)) FOR [SyncParallel]
GO
