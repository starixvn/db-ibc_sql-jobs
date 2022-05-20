
-- Create Role
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or DevDB053 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Sun'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES  ('bodb_3rdProduct'),
				('bodb_licensee'),
				('Affiliate_12BET'),
				('Affiliate_Athena000'),
				--('bodb_CustomerLog'), /*	Note: DB215.bodb_CustomerLog is located on TESTDB055.bodb_CustomerLog	*/
				('bodb_oddsfeed'),
				('Affiliate_Macaubet'),
				('Affiliate_spondemo'),
				('bodb_LicenseeReport'),
				('bodb02'),
				('bodb_OIC'),
				('bodb_report'),
				('bodb_PlaytechCS'),
				('bodb_N88'),
				('bodb_account'),
				('Affiliate_N8G'),
				('Affiliate_N8B'),
				('Affiliate_N88'),
				('bodb_N88_Archive'),
				('bodb_CRM')

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
	SELECT 'Must be run on DB215 or DevDB053 or TESTDB053' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Sun'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES  ('bodb_3rdProduct'),
			('bodb_licensee'),
			('Affiliate_12BET'),
			('Affiliate_Athena000'),
			--('bodb_CustomerLog'),
			('bodb_oddsfeed'),
			('Affiliate_Macaubet'),
			('Affiliate_spondemo'),
			('bodb_LicenseeReport'),
			('bodb02'),
			('bodb_OIC'),
			('bodb_report'),
			('bodb_PlaytechCS'),
			('bodb_N88'),
			('bodb_account'),
			('Affiliate_N8G'),
			('Affiliate_N8B'),
			('Affiliate_N88'),
			('bodb_N88_Archive'),
			('bodb_CRM')

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