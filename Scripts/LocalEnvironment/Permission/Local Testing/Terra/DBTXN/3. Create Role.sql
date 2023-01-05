 
-- Create Role
IF @@SERVERNAME NOT LIKE '%DBTRANS' AND @@SERVERNAME NOT LIKE  '%SiteDB%'
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.dbo.sysdatabases db
WHERE db.name IN  (	'CustDB'
					,'bodb02'
					,'LiveCasino'
					,'LiveCasinoAdmin'
					,'LiveAdmin'
					,'bodb_CustomerLog'
					)

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)
waitfor delay '00:00:01'
--------------------------------------------------------------------------------------
 
-- Grant permission to new role
DECLARE  @strPermission	VARCHAR(MAX) = ''

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