/*
	For Olympus team:
	Affected DB:
		CustDB
		bodb02
		CasinoAdmin
		LiveCasino
		LiveCasinoAdmin
		bodb_CustomerLog

	Windows domain account:
		
*/
-- Create User
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206 or TESTDBTRANS' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('CustDB'),('bodb02'),('CasinoAdmin'),('LiveCasino'),('LiveCasinoAdmin'),('bodb_CustomerLog')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		, ('spvn\dora.le')
		, ('spvn\megan.dinh')
		, ('spvn\tommy.nguyen')
		, ('spvn\Neil.dao')
		, ('spvn\jane.dinh')
		, ('spvn\harley.nguyen')
		, ('spvn\dory.vu')
		, ('spvn\Mike.vu')
		, ('spvn\Kenny.ho')
		
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

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206 or TESTDBTRANS' AS 'Error'

	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Iris'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\kaka.huynh'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('CustDB'),('bodb02'),('CasinoAdmin'),('LiveCasino'),('LiveCasinoAdmin'),('bodb_CustomerLog')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		, ('spvn\dora.le')
		, ('spvn\megan.dinh')
		, ('spvn\tommy.nguyen')
		, ('spvn\Neil.dao')
		, ('spvn\jane.dinh')
		, ('spvn\harley.nguyen')
		, ('spvn\dory.vu')
		, ('spvn\Mike.vu')
		, ('spvn\Kenny.ho')

		
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