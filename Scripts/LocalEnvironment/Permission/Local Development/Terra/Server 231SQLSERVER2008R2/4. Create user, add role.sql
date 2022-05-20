/*
	For Olympus team:
	Affected DB:
		bodb02
		bodb_AGE
		bodb_Summary
		bodb_ChatBot

	Windows domain account:
		spvn\rocky.ping
		spvn\andrew.vu
		spvn\jerry.tran
		spvn\bob.duong
		spvn\martin.tran
		spvn\nancy.dao
		spvn\shane.nguyen
		spvn\kingsley.nguyen
		spvn\rita.bui
		spvn\felix.nguyen
		spvn\lita.tang
*/
-- Create User
IF @@SERVERNAME <> 'DB231\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB231\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_AGE'),('bodb_Summary'), ('bodb_ChatBot')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen'), ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')

/*
	USE DBName
	GO 
	CREATE USER vnXXX FOR LOGIN vnXXX WITH DEFAULT_SCHEMA=[dbo] 
	GO

	-- Delete user: EXEC sp_dropuser 'spvn\xxx.xxx';
*/

SELECT	@strUser = @strUser 
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					----+ 'EXEC sp_dropuser' + '''' + t.name + ''''
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

IF @@SERVERNAME <> 'DB231\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB231\SQLSERVER2008R2' AS 'Error'

	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Terra'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\jerry.tran'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02'),('bodb_AGE'),('bodb_Summary'), ('bodb_ChatBot')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen'), ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')

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