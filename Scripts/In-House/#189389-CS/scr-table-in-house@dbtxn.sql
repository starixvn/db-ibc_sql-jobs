/*<info serverAlias="DBTXN-custdb"></info>*/

use custdb
go

--RepInfo
CREATE TABLE [dbo].[RepInfo](
	[group] [int] NOT NULL,
	[name] [varchar](100) NOT NULL,
	[active] [bit] NOT NULL,
	[version_key] [varchar](100) NOT NULL,
	[version_type] [tinyint] NOT NULL,
	[unique_key] [varchar](100) NULL,
	[get_sp] [varchar](100) NOT NULL,
	[put_sp] [varchar](100) NOT NULL,
	[interval] [int] NOT NULL,
	[back_fix] [int] NOT NULL,
	[delayed_fix] [int] NOT NULL,
	[worker] [varchar](100) NULL,
	[worker_expiry] [datetime2](7) NULL,
	[batch_size] [int] NULL,
	[last_datetime] [datetime2](7) NULL,
	[last_timestamp] [bigint] NULL,
 CONSTRAINT [PK_repinfo] PRIMARY KEY CLUSTERED 
(
	[group] ASC,
	[name] ASC
) ON [DATA]
) ON [DATA]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_group]  DEFAULT ((0)) FOR [group]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_active]  DEFAULT ((0)) FOR [active]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_version_type]  DEFAULT ((0)) FOR [version_type]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_get_sp]  DEFAULT ('') FOR [get_sp]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_put_sp]  DEFAULT ('') FOR [put_sp]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_interval]  DEFAULT ((0)) FOR [interval]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_back_fix]  DEFAULT ((0)) FOR [back_fix]
GO

ALTER TABLE [dbo].[RepInfo] ADD  CONSTRAINT [DF_delayed_fix]  DEFAULT ((0)) FOR [delayed_fix]
GO

--RepInfoGroup
CREATE TABLE [dbo].[RepInfoGroup](
	[GroupID] [tinyint] NOT NULL,
	[SourceServerName] [varchar](20) NOT NULL,
	[SourceDBName] [varchar](30) NOT NULL,
 CONSTRAINT [PK_RepInfoGroup] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
) ON [DATA]
) ON [DATA]
GO

