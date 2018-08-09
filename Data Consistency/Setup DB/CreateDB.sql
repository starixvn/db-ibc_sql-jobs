USE [master]
GO
/*	
	Created:20180912@Kathy
	DB: DBTP/bodb_Consistency
	Task: Data consistency checking
*/
CREATE DATABASE [bodb_Consistency] ON  PRIMARY 
( NAME = N'bodb_Consistency', FILENAME = N'D:\DB234_SQLSERVER2008R2\IBC_DB\bodb_Consistency\bodb_Consistency.mdf' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 10MB ), 
 FILEGROUP [bodb_Consistency_DATA] 
( NAME = N'bodb_Consistency_DATA', FILENAME = N'D:\DB234_SQLSERVER2008R2\IBC_DB\bodb_Consistency\bodb_Consistency_DATA.ndf' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 10MB ), 
 FILEGROUP [bodb_Consistency_INDEX] 
( NAME = N'bodb_Consistency_INDEX', FILENAME = N'D:\DB234_SQLSERVER2008R2\IBC_DB\bodb_Consistency\bodb_Consistency_INDEX.ndf' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 10MB )
 LOG ON 
( NAME = N'bodb_Consistency_log', FILENAME = N'D:\DB234_SQLSERVER2008R2\IBC_DB\bodb_Consistency\bodb_Consistency_log.ldf' , SIZE = 64MB , MAXSIZE = 2048GB , FILEGROWTH = 10MB )
GO

ALTER DATABASE [bodb_Consistency] SET  ENABLE_BROKER 
GO

