/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - CheckSum Vs logs
	DB: DBAGE.bodb_AGE
	Revisions:
		
*/

USE [bodb_AGE]
GO
--DROP TABLE IF EXISTS [dbo].[bettrans_compact_checkSum]
CREATE TABLE [dbo].[bettrans_compact_checkSum](
	[custid] [int] NOT NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[checkSumKey] [int] NULL,
	[checkSumData] [int] NULL,
	[createdTime] [datetime] NULL,
	[notifyStatus] [tinyint] NULL
) ON [cdc_bettrans_data];
GO

CREATE CLUSTERED INDEX CIX_bettrans_compact_checkSum ON [dbo].[bettrans_compact_checkSum]([custid], [winlostdate]) ON [cdc_bettrans_data]
GO

/****** Object:  Table [dbo].[cdc_bettrans_metric_counter]    Script Date: 1/24/2024 9:15:16 AM ******/
--DROP TABLE IF EXISTS [dbo].[cdc_bettrans_metric_counter]
CREATE TABLE [dbo].[cdc_bettrans_metric_counter](
	[rowid] [int] NOT NULL IDENTITY(1, 1),
	[compact_latency] [int] NULL,
	[compact_delayJob] [int] NULL,
	[compact_txnLog] [int] NULL,
	[cdc_pull_latency] [int] NULL,
	[cdc_bet_latency] [int] NULL,
	[creation_time] [datetime] NULL,
	[is_avg] [bit] NULL,
	[cdc_min_rowid] [bigint] NULL,
    [cdc_max_rowid] [bigint] NULL,
	CONSTRAINT [PK_rowid] PRIMARY KEY NONCLUSTERED 
	(
		[rowid] ASC
	) ON [cdc_bettrans_data]
) ON [cdc_bettrans_data]
GO

CREATE CLUSTERED INDEX CIX_cdc_bettrans_metric_counter ON [dbo].[cdc_bettrans_metric_counter](creation_time) ON [cdc_bettrans_data]
GO

--- Seed pool data
INSERT INTO [dbo].[cdc_bettrans_metric_counter]
VALUES(0,0,0,0,0,GETDATE(),0)
GO 100
