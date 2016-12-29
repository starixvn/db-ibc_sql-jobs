/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: SERVER DBLOG/bodb_CustomerLog
	
*/

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
ALTER DATABASE [bodb_CustomerLog] ADD FILE ( NAME = N'serviceBroker_01'
--, FILENAME = N'E:\IBC_DB\bodb_CustomerLog\serviceBroker\serviceBroker_01.ndf' 
-- Local test
--, FILENAME = N'D:\IBC_DB\ServiceBroker\serviceBroker_01.ndf' 

-- Production
, FILENAME = N'G:\IBC_DB\bodb_CustomerLog\serviceBroker\serviceBroker_01.ndf' 
, SIZE = 2048KB , FILEGROWTH = 32768KB ) TO FILEGROUP [ServiceBroker]
GO

-------------------------------------------------

-- create tables
USE bodb_CustomerLog
GO
--drop table [sb].[ConfigurationReference]
go
CREATE TABLE [sb].[ConfigurationReference](
	[FunctionName] varchar(50),
	[MaxReceiveMsg] [int] ,
	[MaxReceiveTimeOut] [int],
	[IsExistingTarget] [BIT] 
	
) ON [ServiceBroker]
GO

CREATE CLUSTERED INDEX [CIX_ConfigurationReference] ON [sb].[ConfigurationReference] 
(
	[FunctionName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ServiceBroker]
GO

GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveMsg]  DEFAULT (1) FOR [MaxReceiveMsg]
GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveTimeOut]  DEFAULT (1) FOR [MaxReceiveTimeOut]
GO
--drop table [sb].[ConfigurationReferenceDetail]
CREATE TABLE [sb].[ConfigurationReferenceDetail](
	[FunctionName] varchar(50),
	[ContractName] varchar(200),
	[MessageType] varchar(200),
	[MinConversation] [int],
	[MaxConversation] [int]
	
) ON [ServiceBroker]
GO
CREATE CLUSTERED INDEX [CIX_ConfigurationReferenceDetail] ON [sb].[ConfigurationReferenceDetail] 
(
	FunctionName ,ContractName
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ServiceBroker]
GO

ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD  CONSTRAINT [DF_ConfigurationReferenceDetail_MinConversation]  DEFAULT (5) FOR [MinConversation]
GO
ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD  CONSTRAINT [DF_ConfigurationReferenceDetail_MaxConversation]  DEFAULT (20) FOR [MaxConversation]
GO
-- drop table [Sb].[ConversationManagement]
CREATE TABLE [Sb].[ConversationManagement](
	[FunctionName] varchar(50), 
	[ContractName] varchar(100),
	[ConversationHandle] Uniqueidentifier null,
	[ConversationNo] int null ,
	[CreatedDate] datetime null,
	[IsValid] BIT null
) ON [ServiceBroker]

CREATE CLUSTERED INDEX inx_ConversationManagement ON sb.ConversationManagement(FunctionName,ContractName, ConversationNo) ON [ServiceBroker]
GO
--DROP TABLE sb.ConversationCount
GO
CREATE TABLE sb.ConversationCount
(
	FunctionName VARCHAR(100),
	ContractName VARCHAR(200),
	Cnt INT
)  ON [ServiceBroker]

CREATE CLUSTERED INDEX inx_ConversationCount ON sb.ConversationCount(FunctionName,ContractName)  ON [ServiceBroker]
GO


CREATE TABLE [Sb].[FailedMessageMonitoring](
	[ID] [bigint] Identity (1,1),
	[FunctionName] varchar(50), 
	[TableName] varchar(200),
	[MessageType] varchar(200),
	[Message] varchar(MAX) null,
	[ErrorMessage] varchar(max) null ,
	[CreatedDate] datetime null,
	[IsResolved] BIT null, 
	
	[ResolvedDate] datetime null
	
) ON [ServiceBroker]
GO
CREATE CLUSTERED INDEX [CIX_FailedMessageMonitoring] ON [sb].[FailedMessageMonitoring] 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ServiceBroker]
GO

ALTER TABLE [sb].[FailedMessageMonitoring] ADD  CONSTRAINT [DF_FailedMessageMonitoring_IsResolved]  DEFAULT (0) FOR [IsResolved]
go
ALTER TABLE [sb].[FailedMessageMonitoring] ADD  CONSTRAINT [DF_FailedMessageMonitoring_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]



--- UserLog_Login
ALTER TABLE UserLog_Login ADD CreatedDate DATETIME NULL
GO
ALTER TABLE eaUserLog_Login ADD CreatedDate DATETIME NULL

GO
--ALTER TABLE  rmUserLog_Login ADD CreatedDate DATETIME NULL