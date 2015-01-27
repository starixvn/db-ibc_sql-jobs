USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_BackupFull]    Script Date: 01/26/2015 23:08:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_BackupFull]
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
Set @Backup_File = 'G:\BACKUP\bodb_backup_P' + @Date + '_' + @Time + 
	CASE @suffix WHEN '' THEN 'DF' ELSE @suffix END + '.bak'
Declare @Desc nvarchar(255) Set @Desc = 'Full Backup for ' + @Date
Declare @Name nvarchar(128) Set @Name = @Date + ' ' + @Time + CASE @suffix WHEN '' THEN ' DIFF_BK' ELSE ' FULL_BK' END

IF @suffix = ''
	BACKUP DATABASE bodb02 TO DISK = @Backup_File
	WITH DIFFERENTIAL,
	 DESCRIPTION = @Desc, NOFORMAT, NOINIT
	,NAME = @Name
	,SKIP, NOREWIND, NOUNLOAD
ELSE
	BACKUP DATABASE bodb02 TO DISK = @Backup_File 
	WITH 
	 DESCRIPTION = @Desc
	,NAME = @Name

GO

GRANT EXECUTE ON [dbo].[Task_BackupFull] TO [bodbadmin] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_BackupFull] TO [ITTim] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_BackupFull] TO [ITVivi] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_BackupFull] TO [vnteam] AS [dbo]
GO


