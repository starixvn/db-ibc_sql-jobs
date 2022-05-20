/*
	For Olympus team:
	Affected DB:
		bodb02
		bodb_ACC
		bodb_Report
		bodb_Archive
		bodb_ACC
		bodb_Message
		bodb_OWP
		bodb_OWP_Test
*/
-- Create Role
IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Olympus'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES ('bodb02'),('bodb_ACC'),('bodb_Report'),('bodb_Archive'),('bodb_ACC'),('bodb_Message'),('bodb_OWP')--,('bodb_OWP_Test')

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

IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Olympus'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_ACC'),('bodb_Report'),('bodb_Archive'),('bodb_ACC'),('bodb_Message'),('bodb_OWP')--,('bodb_OWP_Test')

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