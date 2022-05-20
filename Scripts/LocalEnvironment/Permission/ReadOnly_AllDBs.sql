

USE [master]
GO
CREATE LOGIN [vndba_local] WITH PASSWORD=N'#1234aA#', DEFAULT_DATABASE=[master]
GO

GRANT ALTER TRACE TO [vndba_local]

GO

-- Add Role
USE [msdb]
GO

CREATE USER [vndba_local] FOR LOGIN [vndba_local]

EXEC sp_AddRoleMember 'SQLAgentReaderRole' , [vndba_local]

go 


DECLARE @dbname VARCHAR(500) = '', @sql NVARCHAR(MAX) = ''

DECLARE vendor_cursor CURSOR  
	FOR 
		SELECT NAME  
		FROM sys.databases 
		WHERE NAME NOT IN ('master','tempdb','model','msdb','distribution')
			AND state_desc = 'online'
			

OPEN vendor_cursor  
FETCH NEXT FROM vendor_cursor INTO @dbname

WHILE @@FETCH_STATUS = 0  
BEGIN  

	
	-- db account and role
	SET @sql =  'USE ' + @dbname + ';'
					+ CHAR(13)
					+ 'CREATE USER ' + '[vndba_local]' + ' for login ' + '[vndba_local]' + ' ' + ';'
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + 'db_datareader' + ''',''' + 'vndba_local' + ''' ' + ';'
					+ CHAR(13)

	EXEC sp_executesql @sql

	PRINT @sql

	FETCH NEXT FROM vendor_cursor INTO @dbname

END 


CLOSE vendor_cursor;  
DEALLOCATE vendor_cursor;  