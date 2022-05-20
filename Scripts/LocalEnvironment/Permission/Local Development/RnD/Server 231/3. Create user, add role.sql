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
		FanexDataTests
		bodb_NAPLog
		bodb_RMS

	Windows domain account:
		SPVN\kos.nguyen
		SPVN\ricky.nguyen
		SPVN\jason.ly
		SPVN\james.nguyen
*/
-- Create User
IF @@SERVERNAME NOT IN ('DB231','DB-61\DEVDB053')
BEGIN
	SELECT 'Must be run on DB231' as 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bk'),('bodb_dwrs'),('bodb_Licensee'),('bodb_CustomerLog'),('bodb_Maintenance')
			, ('bodb_NAP'), ('ON_USER')
			--, ('bodb_EAS')--, ('FanexDataTests')
			, ('bodb_NAPLog')
			, ('bodb_RMS')
			, ('bodb_N88_Archive')


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\kos.nguyen'), ('SPVN\ricky.nguyen')--, ('SPVN\jason.ly')
		,('SPVN\james.nguyen')


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

IF @@SERVERNAME NOT IN ('DB231','DB-61\DEVDB053')
BEGIN
	SELECT 'Must be run on DB231' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_owner'

DECLARE @tmpMember TABLE (Name VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bk'),('bodb_dwrs'),('bodb_Licensee'),('bodb_CustomerLog'),('bodb_Maintenance')
			, ('bodb_NAP'), ('ON_USER')
			--, ('bodb_EAS')--, ('FanexDataTests')
			, ('bodb_NAPLog')
			, ('bodb_RMS')
			, ('bodb_N88_Archive')
INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\kos.nguyen'), ('SPVN\ricky.nguyen')--, ('SPVN\jason.ly')
		,('SPVN\james.nguyen')

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