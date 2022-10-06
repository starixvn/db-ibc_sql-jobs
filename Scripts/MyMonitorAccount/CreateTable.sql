/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/

USE [bodb02]
GO
--- WLMonitored_AccumulatedWL
IF OBJECT_Id('WLMonitored_AccumulatedWL') IS NOT NULL
	DROP TABLE WLMonitored_AccumulatedWL

CREATE TABLE [dbo].[WLMonitored_AccumulatedWL](
	[CustId] [int] NULL,
	[AccumWL] [money] NULL,
	[SettlementDate] [date] NULL,
	[UpdatedTime] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[WLMonitored_AccumulatedWL] ADD  CONSTRAINT [DF_WLMonitored_AccumulatedWL_UpdatedTime]  DEFAULT (getdate()) FOR [UpdatedTime]
GO

CREATE CLUSTERED INDEX [CIX_WLMonitored_AccumulatedWL_CustId] ON [dbo].[WLMonitored_AccumulatedWL]
(
	[CustId] ASC,
	[SettlementDate] ASC
) ON [Others_index]
GO

CREATE NONCLUSTERED INDEX [IX_WLMonitored_AccumulatedWL_UpdatedTime] ON [dbo].[WLMonitored_AccumulatedWL]
(
	[UpdatedTime] ASC
) ON [Others_index]
GO
---------------------------------------------------------------------

--- Dep_WLMonitored_AccumulatedWL
IF OBJECT_Id('Dep_WLMonitored_AccumulatedWL') IS NOT NULL
	DROP TABLE Dep_WLMonitored_AccumulatedWL

CREATE TABLE [dbo].[Dep_WLMonitored_AccumulatedWL](
	[CustId] [int] NULL,
	[AccumWL] [money] NULL,
	[SettlementDate] [date] NULL,
	[UpdatedTime] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[Dep_WLMonitored_AccumulatedWL] ADD  CONSTRAINT [DF_Dep_WLMonitored_AccumulatedWL_UpdatedTime]  DEFAULT (getdate()) FOR [UpdatedTime]
GO

CREATE CLUSTERED INDEX [CIX_Dep_WLMonitored_AccumulatedWL_CustId] ON [dbo].[Dep_WLMonitored_AccumulatedWL]
(
	[CustId] ASC,
	[SettlementDate] ASC
) ON [Others_index]
GO
CREATE NONCLUSTERED INDEX [IX_Dep_WLMonitored_AccumulatedWL_UpdatedTime] ON [dbo].[Dep_WLMonitored_AccumulatedWL]
(
	[UpdatedTime] ASC
) ON [Others_index]
GO
---------------------------------------------------------------------

----- WLMonitored_TicketDetails_Pending
IF OBJECT_Id('WLMonitored_TicketDetails_Pending') IS NOT NULL
	DROP TABLE WLMonitored_TicketDetails_Pending

CREATE TABLE [dbo].[WLMonitored_TicketDetails_Pending](
	[Id] [bigint] IDENTITY(1,1),
	[TransId] [bigint] NULL,
	[CustId] [int] NULL,
	[Bettype] [smallint] NULL,
	[Actual_Stake] [money] NULL,
	[Winlost] [money] NULL,
	[SettlementTime] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[WLMonitored_TicketDetails_Pending] ADD  CONSTRAINT [DF_WLMonitored_TicketDetails_Pending_SettlementTime]  DEFAULT (getdate()) FOR [SettlementTime]
GO

CREATE CLUSTERED INDEX [CIX_WLMonitored_TicketDetails_Pending] ON [dbo].[WLMonitored_TicketDetails_Pending]
(
	[Id] ASC
)ON [Others_index]
GO
CREATE NONCLUSTERED INDEX [IX_WLMonitored_TicketDetails_Pending_SettlementTime] ON [dbo].[WLMonitored_TicketDetails_Pending]
(
	[SettlementTime] ASC
) ON [Others_index]
GO


------- WLMonitored_Service_GlobalSetting
IF OBJECT_Id('WLMonitored_Service_GlobalSetting') IS NOT NULL
	DROP TABLE WLMonitored_Service_GlobalSetting

CREATE TABLE [dbo].[WLMonitored_Service_GlobalSetting](
	[ServiceName] [varchar](100) NULL,
	[SettingName] [varchar](100) NULL,
	[SettingValue] [varchar](50) NULL,
	[UpdatedTime] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[WLMonitored_Service_GlobalSetting] ADD  CONSTRAINT [DF_WLMonitored_Service_GlobalSetting_UpdatedTime]  DEFAULT (getdate()) FOR [UpdatedTime]
GO

CREATE CLUSTERED INDEX [CIX_WLMonitored_Service_GlobalSetting_ServiceName] ON [dbo].[WLMonitored_Service_GlobalSetting]
(
	[ServiceName] ASC
)ON [Others_index]
GO
------------------------------------------------------------------------------------------

--------- WLMonitored_Player_History
IF OBJECT_Id('WLMonitored_Player_History') IS NOT NULL
	DROP TABLE WLMonitored_Player_History

CREATE TABLE [dbo].[WLMonitored_Player_History](
	[LogId] [bigint] IDENTITY(1,1),
	[CustId] [int] NULL,
	[SportType] [smallint] NULL,
	[AccumWL] [money] NULL,
	[WinningThreshold] [money] NULL,
	[LosingThreshold] [money] NULL,
	[SettingType] [tinyint] NULL,
	[ReachType] [tinyint] NULL,
	[NotificationType] [tinyint] NULL,
	[CreatedDate] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[WLMonitored_Player_History] ADD  CONSTRAINT [DF_WLMonitored_Player_History_SportType]  DEFAULT ((0)) FOR [SportType]
GO
ALTER TABLE [dbo].[WLMonitored_Player_History] ADD  CONSTRAINT [DF_WLMonitored_Player_History_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE CLUSTERED INDEX [CIX_WLMonitored_Player_History_LogId] ON [dbo].[WLMonitored_Player_History]
(
	[LogId] ASC
) ON [Others_index]
GO
CREATE NONCLUSTERED INDEX [IX_WLMonitored_Player_History_CustID_Sporttype] ON [dbo].[WLMonitored_Player_History]
(
	[CustId] ASC,
	[SportType] ASC
)
INCLUDE([CreatedDate],[WinningThreshold],[LosingThreshold],[SettingType],[AccumWL]) ON [Others_index]
GO
CREATE NONCLUSTERED INDEX [IX_WLMonitored_Player_History_CreatedDate] ON [dbo].[WLMonitored_Player_History]
(
	[CreatedDate] ASC
) ON [Others_index]
GO

----------- Dep_WLMonitored_Player_History
IF OBJECT_Id('Dep_WLMonitored_Player_History') IS NOT NULL
	DROP TABLE Dep_WLMonitored_Player_History

CREATE TABLE [dbo].[Dep_WLMonitored_Player_History](
	[LogId] [bigint] IDENTITY(1,1),
	[CustId] [int] NULL,
	[SportType] [smallint] NULL,
	[AccumWL] [money] NULL,
	[WinningThreshold] [money] NULL,
	[NotificationType] [tinyint] NULL,
	[CreatedDate] [datetime] NULL
) ON [Data]
GO
ALTER TABLE [dbo].[Dep_WLMonitored_Player_History] ADD  CONSTRAINT [DF_Dep_WLMonitored_Player_History_SportType]  DEFAULT ((0)) FOR [SportType]
GO
ALTER TABLE [dbo].[Dep_WLMonitored_Player_History] ADD  CONSTRAINT [DF_Dep_WLMonitored_Player_History_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

CREATE CLUSTERED INDEX [CIX_Dep_WLMonitored_Player_History_LogId] ON [dbo].[Dep_WLMonitored_Player_History]
(
	[LogId] ASC
) ON [Others_index]
GO

CREATE NONCLUSTERED INDEX [IX_Dep_WLMonitored_Player_History_CustID_Sporttype] ON [dbo].[Dep_WLMonitored_Player_History]
(
	[CustId] ASC,
	[SportType] ASC
)
INCLUDE([CreatedDate],[WinningThreshold],[AccumWL]) ON [Others_index]
GO

CREATE NONCLUSTERED INDEX [IX_Dep_WLMonitored_Player_History_CreatedDate] ON [dbo].[Dep_WLMonitored_Player_History]
(
	[CreatedDate] ASC
) ON [Others_index]
GO


