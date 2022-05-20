/*
	For Rome team:
	Affected DB:
		bodb02
		bodb_ACC
		bodb_Report
		bodb_Archive
		bodb_Message
		bodb_OWP

	Windows domain account:
		spvn\kos.nguyen
		spvn\ricky.nguyen
		spvn\jason.ly
		spvn\james.nguyen
*/
-- Create User
IF @@SERVERNAME <> 'DB232'
BEGIN
	SELECT 'Must be run on DB232' as 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_ACC'),('bodb_Report'),('bodb_Archive'),('bodb_Message')
			,('bodb_OWP')


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kos.nguyen'), ('spvn\ricky.nguyen'), ('spvn\jason.ly')
		,('spvn\james.nguyen')


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

IF @@SERVERNAME <> 'DB232'
BEGIN
	SELECT 'Must be run on DB232' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_owner'

DECLARE @tmpMember TABLE (Name VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_ACC'),('bodb_Report'),('bodb_Archive'),('bodb_Message')
			,('bodb_OWP')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kos.nguyen'), ('spvn\ricky.nguyen'), ('spvn\jason.ly')
		,('spvn\james.nguyen')

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