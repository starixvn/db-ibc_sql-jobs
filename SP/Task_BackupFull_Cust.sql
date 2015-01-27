USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_BackupFull_Cust]    Script Date: 01/26/2015 23:16:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_BackupFull_Cust]
	@suffix varchar(20) = ''
AS
--DBCC SHRINKFILE (N'bodb_Log')
-- BACKUP
Declare @Date nvarchar(50)
Declare @Time nvarchar(50)
Set @Date = 
CAST(DATEPART(year, CURRENT_TIMESTAMP) as nvarchar) + 
CASE WHEN DATEPART(month, CURRENT_TIMESTAMP) < 10 THEN '0' + CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) END + 
CASE WHEN DATEPART(day, CURRENT_TIMESTAMP)   < 10 THEN '0' + CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar)   ELSE CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar) END
Set @Time = 
CASE WHEN DATEPART(hour, CURRENT_TIMESTAMP)  < 10 THEN '0' + CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar)  ELSE CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar) END +
CASE WHEN DATEPART(minute,CURRENT_TIMESTAMP) < 10 THEN '0' + CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) END

Declare @Backup_File nvarchar(200)
Set @Backup_File = 'G:\BACKUP\CustDB_backup_' + @Date + '_' + @Time + 
	CASE @suffix WHEN '' THEN 'DF' ELSE @suffix END + '.bak'
Declare @Desc nvarchar(255) Set @Desc = 'Full Backup for ' + @Date
Declare @Name nvarchar(128) Set @Name = @Date + ' ' + @Time + CASE @suffix WHEN '' THEN ' DIFF_BK' ELSE ' FULL_BK' END

IF @suffix = ''
	BACKUP DATABASE CustDB TO DISK = @Backup_File
	WITH DIFFERENTIAL,
	 DESCRIPTION = @Desc, NOFORMAT, NOINIT
	,NAME = @Name
	,SKIP, NOREWIND, NOUNLOAD
	,COMPRESSION
	,CHECKSUM
ELSE
	BACKUP DATABASE CustDB TO DISK = @Backup_File 
	WITH 
	 DESCRIPTION = @Desc
	,NAME = @Name
	,COMPRESSION
	,CHECKSUM

GO


