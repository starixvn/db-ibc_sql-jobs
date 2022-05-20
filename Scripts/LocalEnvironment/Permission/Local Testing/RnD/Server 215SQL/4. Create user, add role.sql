/*
	For RnD team:
	Affected DB:
		bodb_Chatbot

	Windows domain account:
		spvn\harrison.nguyen
*/
-- Create User
IF @@SERVERNAME <> 'DB215\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB215\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb_Chatbot')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\harrison.nguyen')

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

IF @@SERVERNAME <> 'DB215\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB215\SQLSERVER2008R2' AS 'Error'

	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_NexOps'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb_Chatbot')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\harrison.nguyen')

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