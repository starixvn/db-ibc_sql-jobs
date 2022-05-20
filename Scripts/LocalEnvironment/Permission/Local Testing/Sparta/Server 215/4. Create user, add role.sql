/*
	For Sparta team:
		spvn\alex.nguyen
		spvn\joseph.pham
		spvn\bruce.bui
		spvn\walter.tran
		spvn\scofield.huynh
		spvn\amanda.luong
		spvn\parsons.nguyen
		spvn\hubert.duong
		spvn\mason.nguyen

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
-- Create User
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
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

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')
		, ('spvn\hubert.duong'), ('spvn\mason.nguyen'), ('spvn\howard.nguyen')

/*
	USE DBName
	GO 
	CREATE USER vnXXX FOR LOGIN vnXXX WITH DEFAULT_SCHEMA=[dbo] 
	GO
*/

SELECT	@strUser = @strUser 
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE NAME = ''' + t.Name + ''') '
					+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo] ' + ';'
					+ CHAR(13)
					+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT	t.Name
		FROM	@tmpMember t
	) t

EXEC (@strUser)
GO
-------------------------------------------
-------------------------------------------


-- Add Role for member
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Sparta'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\alex.nguyen'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
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

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')
		, ('spvn\hubert.duong'), ('spvn\mason.nguyen'), ('spvn\howard.nguyen')

UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END
/*
	USE DBName
	GO
	EXEC sp_AddRoleMember 'db_xxx', 'vnxxx'
	GO
*/
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + t.RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name, RoleName
		FROM @tmpMember 
	)t
	
EXEC (@strUser)

GO