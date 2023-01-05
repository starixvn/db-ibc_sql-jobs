/*
	For Olympus team:
	Affected DB:
		bodb02

	
*/
-- Create User
IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
 		,@RoleName VARCHAR(50) = 'db_SPU'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50)

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02') 

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu'), ('spvn\terry.nguyen')
		,('spvn\casey.huynh'), ('spvn\john.ngo'),  ('spvn\harvey.nguyen')
		, ('spvn\victoria.le')

UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END

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

waitfor delay '00:00:01'
 
-------------------------------------------
SET @strUser = ''

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