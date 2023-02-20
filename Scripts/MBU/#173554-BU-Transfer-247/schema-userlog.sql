/*<info serverAlias="DBTXN-bodb_CustomerLog,DBLOG-bodb_CustomerLog"></info>*/

USE bodb_CustomerLog
GO

select * from sys.database_files

--G:\SQLSERVER2019_DEVSITEDB\IBC_DB\bodb_CustomerLog\bodb_CustomerLog.mdf
ALTER DATABASE bodb_CustomerLog ADD FILEGROUP Task_UserLog;
ALTER DATABASE bodb_CustomerLog ADD FILE (NAME = N'Task_UserLog', FILENAME = N'G:\SQLSERVER2019_DEVSITEDB\IBC_DB\bodb_CustomerLog\Task_UserLog.ndf', SIZE = 512KB, MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB) TO FILEGROUP Task_UserLog


CREATE TABLE [dbo].[Task_UserLog](
	[logid] [bigint] IDENTITY(1,1) NOT NULL,
	[servername] varchar(128) NOT NULL,
	[userid] [int] NULL,
	[doing] [nvarchar](512) NULL,
	[logdate] [datetime] NULL
) ON [Task_UserLog]
GO

CREATE CLUSTERED INDEX CIX_Task_UserLog ON [dbo].[Task_UserLog](logdate) ON [Task_UserLog]
GO

CREATE NONCLUSTERED INDEX IX_logid ON [dbo].[Task_UserLog](logid) ON [Task_UserLog]
GO

ALTER TABLE [dbo].[Task_UserLog] ADD  CONSTRAINT [DF_Task_UserLog_logdate]  DEFAULT (getdate()) FOR [logdate]
GO