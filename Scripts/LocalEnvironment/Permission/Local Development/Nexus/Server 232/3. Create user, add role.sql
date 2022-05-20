/*
	For Olympus team:
	Affected DB:
		bodb02
		bodb_CRM
		bodb_oddsfeed

	Windows domain account:
		spvn\quinn.vo
		spvn\tim.trinh
		spvn\scofield.huynh
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
	VALUES ('bodb02'),('bodb_CRM'),('bodb_oddsfeed'),('bodb_NAPLOG'), ('bodb_OIC')


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\quinn.vo'), ('spvn\tim.trinh'), ('spvn\scofield.huynh'), ('spvn\elton.ton'), ('spvn\oliver.dang')


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
	VALUES ('bodb02'),('bodb_CRM'),('bodb_oddsfeed'),('bodb_NAPLOG'), ('bodb_OIC')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\quinn.vo'), ('spvn\tim.trinh'), ('spvn\scofield.huynh'), ('spvn\elton.ton'), ('spvn\oliver.dang')

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