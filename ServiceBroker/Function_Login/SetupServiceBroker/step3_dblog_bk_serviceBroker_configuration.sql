-- LOCAL: db230\sqlserver2008R2. PRODUCTION: DBCUST
-- Enable service broker
USE [master]
GO
ALTER DATABASE [bodb_CustomerLog] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [bodb_CustomerLog] SET  ENABLE_BROKER WITH NO_WAIT
GO
ALTER DATABASE [bodb_CustomerLog] SET TRUSTWORTHY ON
GO
ALTER DATABASE [bodb_CustomerLog] SET MULTI_USER
GO
------------------------------------------------

-- create new schema/owner for service broker
USE bodb_CustomerLog
GO
CREATE SCHEMA [sb] AUTHORIZATION [dbo]
GO
-------------------------------------------------

-- add new file/filegroup for service broker
USE [master]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILEGROUP [ServiceBroker]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILE ( NAME = N'serviceBroker_01', FILENAME = N'G:\IBC_DB\custdb\serviceBroker\serviceBroker_01.ndf' , SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [ServiceBroker]
GO
ALTER DATABASE [bodb_CustomerLog] ADD FILE ( NAME = N'serviceBroker_02', FILENAME = N'G:\IBC_DB\custdb\serviceBroker\serviceBroker_02.ndf' , SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [ServiceBroker]
GO
-------------------------------------------------

-- create tables
USE bodb_CustomerLog
GO
CREATE TABLE [sb].[ConfigurationReference](
	[FunctionID] [int],
	[FunctionName] varchar(50), 
	[MaxConversation] [int] ,
	[MaxReceiveMsg] [int] ,
	[MaxReceiveTimeOut] [int] 
	
) ON [ServiceBroker]
GO

CREATE CLUSTERED INDEX [CIX_ConfigurationReference] ON [sb].[ConfigurationReference] 
(
	[FunctionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ServiceBroker]
GO

ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxConversation]  DEFAULT (1) FOR [MaxConversation]
GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveMsg]  DEFAULT (1) FOR [MaxReceiveMsg]
GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveTimeOut]  DEFAULT (1) FOR [MaxReceiveTimeOut]
GO
