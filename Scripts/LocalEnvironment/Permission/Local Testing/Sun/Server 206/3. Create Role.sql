

-- Create Role
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' , 'TESTDB053\TESTSITEDB', 'DB-60\DEVDBTRANS', 'DB62\DEVSiteDB' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Sun'
		,@strRole	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name 
FROM master.sys.databases db
WHERE name IN(	'bodb02',
				'CustDB',
				'bodb_CustomerLog',
				'LiveCasino',
				'LiveCasinoAdmin',
				'LogDB'
			)

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)

WAITFOR DELAY '00:00:02'
---------------------------------------------------------------

-- Grant permission to new role
DECLARE @strPermission	VARCHAR(MAX) = ''
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