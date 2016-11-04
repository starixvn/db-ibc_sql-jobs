/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBCUST/CUSTDB 
	
*/	

-- Enable service broker
USE [master]
GO
ALTER DATABASE [CustDB] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [CustDB] SET  ENABLE_BROKER WITH NO_WAIT
GO
ALTER DATABASE [CustDB] SET TRUSTWORTHY ON
GO
ALTER DATABASE [CustDB] SET MULTI_USER
GO
------------------------------------------------

-- create new schema/owner for service broker
USE CustDB
GO
CREATE SCHEMA [sb] AUTHORIZATION [dbo]
GO
-------------------------------------------------

-- add new file/filegroup for service broker
USE [master]
GO
ALTER DATABASE [CustDB] ADD FILEGROUP [ServiceBroker]
GO
ALTER DATABASE [CustDB] ADD FILE ( NAME = N'serviceBroker_01'
, FILENAME = N'E:\SQLSERVER2008R2\IBC_DB\CustDB\serviceBroker\serviceBroker_01.ndf' 
--, FILENAME = N'G:\IBC_DB\custdb\serviceBroker\serviceBroker_01.ndf' 

, SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [ServiceBroker]
GO
ALTER DATABASE [CustDB] ADD FILE ( NAME = N'serviceBroker_02'
, FILENAME = N'E:\SQLSERVER2008R2\IBC_DB\CustDB\serviceBroker\serviceBroker_02.ndf' 
--, FILENAME = N'G:\IBC_DB\custdb\serviceBroker\serviceBroker_02.ndf' 
, SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [ServiceBroker]
GO
-------------------------------------------------

-- create tables
USE CustDB
GO
CREATE TABLE [sb].[ConfigurationReference](
	[FunctionID] [int],
	[FunctionName] varchar(50),
	[ContractName] varchar(100), 
	
	[MaxConversation] [int],
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

CREATE TABLE [Sb].[ConversationManagement](
	[FunctionName] varchar(50), 
	[ContractName] varchar(100),
	[ConversationHandle] Uniqueidentifier null,
	[ConversationNo] int null ,
	[CreatedDate] datetime null,
	[IsValid] BIT null
) ON [ServiceBroker]

CREATE CLUSTERED INDEX inx_ConversationManagement ON sb.ConversationManagement(FunctionName, ConversationNo)
GO
CREATE TABLE sb.ConversationCount
(
	FunctionName VARCHAR(100),
	Cnt INT
)  ON [ServiceBroker]

CREATE CLUSTERED INDEX inx_ConversationCount ON sb.ConversationCount(FunctionName)  ON [ServiceBroker]
GO


