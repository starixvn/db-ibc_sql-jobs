

-- Create Role
IF @@SERVERNAME NOT IN ( 'DB-61\DEVDB055' ,'TESTDB055' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Olympus'
		,@strRole	VARCHAR(MAX) = ''
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES ( 'bodb_CustomerLog')
			 , ('bodb_CustomerLog_archive' )
			 , ('LogTDB' )

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)
waitfor delay '00:00:01'
 

-- Grant permission to new role
  
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))
 

INSERT INTO @tmpPermission (PermissionName)
	VALUES ('VIEW DEFINITION'),('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('EXECUTE')

SELECT @strPermission = @strPermission + ' '
					 + 'USE ' + d.DBName + ' ' + ';'
					 + CHAR(13)
					 + 'GRANT ' + p.PermissionName + ' ON SCHEMA::dbo TO ' + @RoleName + ' ' + ';'
					 + CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT PermissionName
		FROM	@tmpPermission
	) p
EXEC (@strPermission)
GO