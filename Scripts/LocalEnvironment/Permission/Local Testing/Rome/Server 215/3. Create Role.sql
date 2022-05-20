/*
	For Rome team:
	Affected DB:
		bodb02
		BK
		bodb_dwrs
		bodb_License
		bodb_CustomerLog
		bodb_Maintenance
		bodb_NAP
		ON_USER
		bodb_EAS
		bodb_Summary
*/
-- Create Role
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Rome'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES ('bodb02'),('bodb_AGE'),('bk'),('bodb_dwrs'),('bodb_Licensee')
			--,('bodb_CustomerLog')
			,('bodb_Maintenance')
			, ('bodb_NAP'), ('ON_USER')
			--, ('bodb_EAS')
			, ('bodb_Summary')

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

IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Rome'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bk'),('bodb_dwrs'),('bodb_Licensee')
	--,('bodb_CustomerLog')
	,('bodb_Maintenance')
	, ('bodb_NAP'), ('ON_USER')
			--, ('bodb_EAS')

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