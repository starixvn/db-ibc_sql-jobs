 

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS', 'TESTDB053\TESTSITEDB' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'
	RETURN
END

-- Create User
DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT name FROM master.sys.sysdatabases 
WHERE name IN (
		'CustDB'
		,'bodb02'
		,'bodb_CustomerLog'
		,'LogDB'
		,'CasinoAdmin'
		,'LiveCasino'
		,'LiveCasinoAdmin'
		)

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		, ('spvn\dora.le')
		, ('spvn\megan.dinh')
		, ('spvn\tommy.nguyen')
		, ('spvn\Neil.dao')
		, ('spvn\jane.dinh')
		, ('spvn\harley.nguyen') 
		, ('spvn\Mike.vu')
		, ('spvn\Kenny.ho')
		,('spvn\ariana.nguyen')
		,('spvn\benjamin.nguyen')
		
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
WAITFOR DELAY '00:00:01'
 
-- Add Role for member
 
DECLARE @RoleName VARCHAR(50) = 'db_Iris'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\kaka.huynh'
 
UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END
 
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