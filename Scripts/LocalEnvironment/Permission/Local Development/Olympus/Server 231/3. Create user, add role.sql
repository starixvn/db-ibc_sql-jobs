/*
	For Olympus team:
	Affected DB:
		bodb02
		bodb_NAP
		bk
		bodb_Maintenance
		bodb_Licensee
		bodb_CustomerLog
		bodb_RMS
		bodb_dwrs
		bodb_OIC
		bodb_Account
		bodb_Maintenance
		bodb_MMS
		bodb_LicenseeReport
		bodb_OLAP

	Windows domain account:
		spvn\jacob.phan
		spvn\robert.tran
		spvn\kaden.trinh
		spvn\leo.vo
		spvn\franklin.nguyen
		spvn\alan.nguyen
		spvn\raymond.le
		spvn\charles.nguyen
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
	VALUES ('bodb02'),('bodb_NAP'),('bk'),('bodb_Maintenance'),('bodb_Licensee'),('bodb_CustomerLog'),('bodb_RMS'), ('bodb_dwrs'), ('bodb_OIC')
		, ('bodb_Account'), ('bodb_MMS'), ('bodb_Maintenance'), ('bodb_LicenseeReport'), ('bodb_archive'), ('bodb_OLAP'), ('bodb_Staging')


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen'), ('spvn\raymond.le'), ('spvn\charles.nguyen')


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
	VALUES ('bodb02'),('bodb_NAP'),('bk'),('bodb_Maintenance'),('bodb_Licensee'),('bodb_CustomerLog'),('bodb_RMS'), ('bodb_dwrs'), ('bodb_OIC')
		, ('bodb_Account'), ('bodb_MMS'), ('bodb_Maintenance'), ('bodb_LicenseeReport'), ('bodb_archive'), ('bodb_OLAP'), ('bodb_Staging')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen'), ('spvn\raymond.le'), ('spvn\charles.nguyen')

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