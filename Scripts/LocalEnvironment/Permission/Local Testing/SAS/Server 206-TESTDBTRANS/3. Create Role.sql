

-- Create Role
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206 or TESTDBTRANS' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_SAS'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.sys.databases db
WHERE db.name not in ('master','tempdb','model','msdb', 'distribution', 'SSISDB','ReportServer', 'ReportServerTempDB', 'RedGate')
		AND db.state = 0 --ONLINE

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)
GO
-------------------------------------------
-------------------------------------------

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206 or TESTDBTRANS' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_SAS'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.sys.databases db
WHERE db.name not in ('master','tempdb','model','msdb', 'distribution', 'SSISDB','ReportServer', 'ReportServerTempDB', 'RedGate')
		AND db.state = 0 --ONLINE


SELECT @strPermission = @strPermission + ' '
					 + 'USE ' + d.DBName + ' ' + ';'
					 + CHAR(13)
					 + 'ALTER ROLE [db_owner] ADD MEMBER '  + @RoleName + ' ' + ';'
					 + CHAR(13)
FROM	@tmpAffectedDB d
EXEC (@strPermission)
GO
