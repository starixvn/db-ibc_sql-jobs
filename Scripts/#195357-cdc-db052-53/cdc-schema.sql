
use bodb_cdc
go
ALTER DATABASE bodb_cdc ADD FILEGROUP [cdc_bettrans_data];
GO  

ALTER DATABASE bodb_cdc    
ADD FILE   
( NAME = N'cdc_bettrans_data', FILENAME = N'G:\SQLSERVER2019_DEVDB053\IBC_DB\bodb_cdc\cdc_bettrans_data.ndf' , SIZE = 32768KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ) -- Edit path file by environment deployed
TO FILEGROUP [cdc_bettrans_data];  
GO

use bodb02
go
ALTER DATABASE bodb02 ADD FILEGROUP [cdc_bettrans_data];
GO  

ALTER DATABASE bodb02    
ADD FILE   
( NAME = N'cdc_bettrans_data', FILENAME = N'G:\SQLSERVER2019_DEVDB053\IBC_DB\bodb02\cdc_bettrans_data.ndf' , SIZE = 32768KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ) -- Edit path file by environment deployed
TO FILEGROUP [cdc_bettrans_data];  
GO

go

use bodb_cdc
go


CREATE TABLE [dbo].[cdc_pull_data_batching](
	[tableName] [varchar](200) NULL,
	[fromLSN] [binary](10) NULL,
	[toLSN] [binary](10) NULL,
	[loop] [bit] NULL,
	[pageIndex] [int] NULL,
	[totalRows] [bigint] NULL
) ON [PRIMARY]
GO


CREATE UNIQUE CLUSTERED INDEX [cix_cdc_pull_data_batching] ON [dbo].[cdc_pull_data_batching]
(
	[tableName] ASC
) ON [PRIMARY]
GO


CREATE TABLE [dbo].[cdc_pull_data_batching_history](
	[tableName] [varchar](200) NULL,
	[fromLSN] [binary](10) NULL,
	[toLSN] [binary](10) NULL,
	[loop] [bit] NULL,
	[pageIndex] [int] NULL,
	[totalRows] [bigint] NULL,
	[logdate] [datetime2](7) NULL
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [cix_cdc_pull_data_batching_history] ON [dbo].[cdc_pull_data_batching_history]
(
	[logdate] ASC
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_cdc_pull_data_batching_history_tableName] ON [dbo].[cdc_pull_data_batching_history]
(
	[tableName] ASC
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[cdc_pull_data_batching_history] ADD  DEFAULT (sysdatetime()) FOR [logdate]
GO

CREATE TRIGGER [dbo].[trgg_cdc_pull_data_batching_upd]
   ON  [dbo].[cdc_pull_data_batching]
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	insert into dbo.cdc_pull_data_batching_history([tableName], [fromLSN], [toLSN], [loop], [pageIndex], [totalRows])
	select [tableName], [fromLSN], [toLSN], [loop], [pageIndex], [totalRows]
	from inserted
END
GO


CREATE TABLE [dbo].[cdc_bettrans](
	[rowId] bigint identity(1,1),
	[__$start_lsn] [binary](10) NOT NULL,
	[__$end_lsn] [binary](10) NULL,
	[__$seqval] [binary](10) NOT NULL,
	[__$operation] [int] NOT NULL,
	[__$update_mask] [varbinary](128) NULL,
	[transid] [bigint] NULL,
	[custid] [int] NULL,
	[transdate] [datetime] NULL,
	[odds] [smallmoney] NULL,
	[stake] [money] NULL,
	[status] [nvarchar](10) NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[apositiontaking] [smallmoney] NULL,
	[mpositiontaking] [smallmoney] NULL,
	[tpositiontaking] [smallmoney] NULL,
	[playerdiscount] [decimal](9, 8) NULL,
	[discount] [decimal](9, 8) NULL,
	[adiscount] [decimal](9, 8) NULL,
	[liveindicator] [bit] NULL,
	[betteam] [nvarchar](10) NULL,
	[refno] [bigint] NULL,
	[winlostdate] [smalldatetime] NULL,
	[oddsspread] [money] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[betid] [bigint] NULL,
	[modds] [smallmoney] NULL,
	[bettype] [smallint] NULL,
	[betdaqid] [bigint] NULL,
	[actual_stake] [money] NULL,
	[currency] [tinyint] NULL,
	[sdiscount] [decimal](9, 8) NULL,
	[scomm] [money] NULL,
	[spositiontaking] [smallmoney] NULL,
	[swinlost] [money] NULL,
	[srecommend] [int] NULL,
	[statusID] [tinyint] NULL,
	[SettlementTime] [datetime] NULL,
	[epositiontaking] [smallmoney] NULL,
	[__$command_id] [int] NULL,
	[actiondate] datetime
) ON [cdc_bettrans_data]
GO

CREATE UNIQUE CLUSTERED INDEX [cix_cdc_bettrans] ON [dbo].[cdc_bettrans]
(
	[__$start_lsn] ASC,
	[__$command_id] ASC,
	[__$seqval] ASC,
	[__$operation] ASC
) ON [cdc_bettrans_data]
GO

CREATE NONCLUSTERED INDEX [ix_cdc_bettrans_actiondate] on [dbo].[cdc_bettrans]
(
	[actiondate] ASC
) ON [cdc_bettrans_data]

ALTER TABLE [dbo].[cdc_bettrans] ADD CONSTRAINT [DF_cdc_bettrans_actiondate]  DEFAULT (getdate()) FOR [actiondate]
GO

CREATE function [dbo].[f_dba_GetDelayTime]
(
	@KeyId varchar(50)
) 
returns varchar(50)
as
begin
	return (select case when @KeyId = 'translog' then '00:00:00:012' --cdc pull bettrans
						when @KeyId = 'nodata' then '00:00:03:000' --cdc pull nodata
						when @KeyId = 'removeold' then '00:00:00:123' --cdc pull nodata
						else '00:00:00:100' end)
end
GO

create table SystemSettings (VName varchar(200), VValue varchar(200))
create clustered index cix_SystemSettings on SystemSettings(VName)
insert into dbo.SystemSettings(VName, VValue) values('JobDeploymentDate', '')

insert into cdc_pull_data_batching(tableName) values('bettrans')