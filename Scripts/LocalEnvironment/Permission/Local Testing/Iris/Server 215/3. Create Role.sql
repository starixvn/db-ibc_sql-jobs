
-- Create Role
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Iris'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES 
		-- ('bodb_CustomerLog')
			('bodb_Notification')
			,('bodb_3rdProduct')
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
			,('bodb_PlaytechCS')
			,('bodb_N88')
			,('bodb_Summary')
			,('bodb_ODS')
			--,('bodb_Age')
			,('bodb_OLAP')
			,('bodb_CRM')
			,('bodb_adhoc')

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
DECLARE @RoleName VARCHAR(50) = 'db_Iris'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES
		-- ('bodb_CustomerLog')
			('bodb_Notification')
			,('bodb_3rdProduct')
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
			,('bodb_PlaytechCS')
			,('bodb_N88')
			,('bodb_Summary')
			,('bodb_ODS')
			--,('bodb_Age')
			,('bodb_OLAP')
			,('bodb_CRM')
			,('bodb_adhoc')

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