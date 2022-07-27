/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/ 
/*
	Created: 20220725@Bobby
	DB: DBBAH.bodb02
	Task: 
	Revision:
		- 20220725@Bobby: Prepare filegroup and log table [Redmine:#175815]
*/
USE [master]
GO
ALTER DATABASE [BalanceRecord] ADD FILEGROUP [BR_22M01]
GO
ALTER DATABASE [BalanceRecord] ADD FILEGROUP [BR_22M02]
GO
ALTER DATABASE [BalanceRecord] ADD FILEGROUP [BR_22M03]
GO

USE [master]
GO
ALTER DATABASE [BalanceRecord] ADD FILE ( NAME = N'BR_22M01', FILENAME = N'T:\USER_DB\BalanceRecord\BR_22M01.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [BR_22M01]
GO
ALTER DATABASE [BalanceRecord] ADD FILE ( NAME = N'BR_22M02', FILENAME = N'T:\USER_DB\BalanceRecord\BR_22M02.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [BR_22M02]
GO
ALTER DATABASE [BalanceRecord] ADD FILE ( NAME = N'BR_22M03', FILENAME = N'T:\USER_DB\BalanceRecord\BR_22M03.ndf' , SIZE = 1024KB , FILEGROWTH = 32768KB ) TO FILEGROUP [BR_22M03]
GO

use [BalanceRecord];
GO
CREATE TABLE dbo.DBA_AutoPartition_Logs
(
	table_name		VARCHAR(128),
	running_month	DATETIME,
	clean_range		DATETIME,
	clean_command	VARCHAR(1000),
	split_range		DATETIME,
	split_command	VARCHAR(1000),
	start_time		DATETIME,
	end_time		DATETIME,
	error			VARCHAR(1000),
	CONSTRAINT PK_running_month PRIMARY KEY (table_name, running_month, clean_range)
) ON [PRIMARY]