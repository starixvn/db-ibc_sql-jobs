 
-- Create Role
IF @@SERVERNAME NOT IN ('DB-61\DevDB053','TESTDB053')
BEGIN
	SELECT 'Must be run on DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES  ('bodb_3rdProduct')
				,('bodb_Account')
				,('bodb_archive')
				,('bodb_Customer')
				,('bodb_dwrs')
				,('bodb_LCC')
				,('bodb_licensee')
				,('bodb_LicenseeReport')
				,('bodb_LicenseeReportArchive')
				,('bodb_MMS')
				,('bodb_NAP')
				,('bodb_Staging')
				,('bodb02')
				,('bodb_OIC')
				,('bodb_report')
				,('bodb_RMS')
				,('bk')
				,('bodb_PlaytechCS')
				, ('ON_USER')
				,('bodb_Maintenance')

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)
GO
--------------------------------------------------------------------------------------

IF @@SERVERNAME NOT IN ('DB-61\DevDB053','TESTDB053')
BEGIN
	SELECT 'Must be run on DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES  ('bodb_3rdProduct')
				,('bodb_Account')
				,('bodb_archive')
				,('bodb_Customer')
				,('bodb_dwrs')
				,('bodb_LCC')
				,('bodb_licensee')
				,('bodb_LicenseeReport')
				,('bodb_LicenseeReportArchive')
				,('bodb_MMS')
				,('bodb_NAP')
				,('bodb_Staging')
				,('bodb02')
				,('bodb_OIC')
				,('bodb_report')
				,('bodb_RMS')
				,('bk')
				,('bodb_PlaytechCS')
				, ('ON_USER')
				,('bodb_Maintenance')

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