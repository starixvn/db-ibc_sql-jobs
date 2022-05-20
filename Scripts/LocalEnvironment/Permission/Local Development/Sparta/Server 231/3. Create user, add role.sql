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
		Deposit_DB
		bodb_LicenseeReportArchive

*/
-- Create User
IF @@SERVERNAME <> 'DB231'
BEGIN
	SELECT 'Must be run on DB231' as 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_Licensee'),('bodb_LicenseeReport'),('bodb_CRM'),('bodb_OIC')
		,('Affiliate_Athena000'),('Affiliate_12BET')
		--,('AffPortal_12BET') -- Database 'AffPortal_12BET' cannot be opened because it is offline.
		,('Affiliate_Spondemo')
		--,('Affiliate_MacauBet') -- Database 'Affiliate_MacauBet' does not exist
		,('bodb_3rdProduct')
		,('bodb_PlaytechCS')
		,('bodb_CustomerLog')
		,('bodb_oddsfeed')
		,('bodb_NAP')
		,('bodb_NAPLOG')
		,('Deposit_DB')
		,('bodb_LicenseeReportArchive')


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

IF @@SERVERNAME <> 'DB231'
BEGIN
	SELECT 'Must be run on DB231' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_owner'

DECLARE @tmpMember TABLE (Name VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_Licensee'),('bodb_LicenseeReport'),('bodb_CRM'),('bodb_OIC')
		,('Affiliate_Athena000'),('Affiliate_12BET')
		--,('AffPortal_12BET') -- Database 'AffPortal_12BET' cannot be opened because it is offline.
		,('Affiliate_Spondemo')
		--,('Affiliate_MacauBet') -- Database 'Affiliate_MacauBet' does not exist
		,('bodb_3rdProduct')
		,('bodb_PlaytechCS')
		,('bodb_CustomerLog')
		,('bodb_oddsfeed')
		,('bodb_NAP')
		,('bodb_NAPLOG')
		,('Deposit_DB')
		,('bodb_LicenseeReportArchive')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')
		, ('spvn\hubert.duong'), ('spvn\mason.nguyen'), ('spvn\howard.nguyen')

/*
	USE DBName
	GO
	EXEC sp_AddRoleMember 'db_xxx', 'vnxxx'
	GO
*/
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + @RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name
		FROM @tmpMember 
	)t

EXEC (@strUser)

GO