

-- Create User

 ---DBLOG, DB042, 	DBOST, DBBOF, 	DBUserLog
IF @@SERVERNAME NOT IN ( 'DB-61\DEVDB055' ,'TESTDB055' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''		
		,@RoleName VARCHAR(50) = 'db_Legion'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\kos.nguyen'

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb_CustomerLog')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kos.nguyen' )
			,('spvn\parsons.nguyen') 
			, ('spvn\hogan.pham')
			, ('spvn\walter.nguyen')
			, ('spvn\kai.le')
			,('spvn\cody.nguyen')

UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END

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
		--	LEFT JOIN sys.database_principals s
		--		ON t.Name = s.name
		--WHERE	s.name IS NULL
	) t


EXEC (@strUser)
waitfor delay '00:00:01'
 
-- Add Role for member
 
SET @strUser  = '' 
 
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