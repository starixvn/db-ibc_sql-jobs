/*
	For Sparta team:
		spvn\alex.nguyen
		spvn\joseph.pham
		spvn\bruce.bui
		spvn\walter.tran
		spvn\scofield.huynh
		spvn\amanda.luong
		spvn\parsons.nguyen

	Affected DB:
		bodb02
		bodb_Licensee
		bodb_LicenseeReport
		bodb_CRM
		bodb_OIC
		Affiliate_Athena000
		Affiliate_12BET
		AffPortal_12BET
		Affiliate_Spondemo
		Affiliate_MacauBet
		bodb_3rdProduct
		bodb_PlaytechCS
		bodb_CustomerLog
		bodb_oddsfeed
		bodb_NAP
		bodb_NAPLOG
		bodb_Account
		Deposit_DB

*/
-- Create Role
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Sparta'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_Licensee'),('bodb_LicenseeReport'),('bodb_CRM'),('bodb_OIC')
		,('Affiliate_Athena000'),('Affiliate_12BET'),('AffPortal_12BET'),('Affiliate_Spondemo'),('Affiliate_MacauBet')
		,('bodb_3rdProduct')
		,('bodb_PlaytechCS')
		,('bodb_CustomerLog')
		,('bodb_oddsfeed')
		,('bodb_NAP')
		,('bodb_NAPLOG')
		,('bodb_Account')
		,('Deposit_DB')

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
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Sparta'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_Licensee'),('bodb_LicenseeReport'),('bodb_CRM'),('bodb_OIC')
		,('Affiliate_Athena000'),('Affiliate_12BET'),('AffPortal_12BET'),('Affiliate_Spondemo'),('Affiliate_MacauBet')
		,('bodb_3rdProduct')
		,('bodb_PlaytechCS')
		,('bodb_CustomerLog')
		,('bodb_oddsfeed')
		,('bodb_NAP')
		,('bodb_NAPLOG')
		,('bodb_Account')
		,('Deposit_DB')

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

DECLARE @RoleName VARCHAR(50) = 'db_Sparta'
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpDBPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_Licensee'),('bodb_LicenseeReport'),('bodb_CRM'),('bodb_OIC')
		,('Affiliate_Athena000'),('Affiliate_12BET'),('AffPortal_12BET'),('Affiliate_Spondemo'),('Affiliate_MacauBet')
		,('bodb_3rdProduct')
		,('bodb_PlaytechCS')
		,('bodb_CustomerLog')
		,('bodb_oddsfeed')
		,('bodb_NAP')
		,('bodb_NAPLOG')
		,('bodb_Account')
		,('Deposit_DB')

INSERT INTO @tmpDBPermission (PermissionName)
	VALUES ('SHOWPLAN')
 
SELECT @strPermission = @strPermission + ' '
					 + 'USE ' + d.DBName + ' ' + ';'
					 + CHAR(13)
					 + 'GRANT ' + p.PermissionName + ' TO ' + @RoleName + ' ' + ';'
					 + CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT PermissionName
		FROM	@tmpDBPermission
	) p

EXEC (@strPermission)
GO
