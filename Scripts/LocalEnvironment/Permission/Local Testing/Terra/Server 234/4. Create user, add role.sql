 
-- Create User
IF @@SERVERNAME NOT IN ( 'DB232', 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB232 or TESTDB061' AS 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02')
			,('bodb_ACC')
			,('bodb_Report')
			,('bodb_Archive')
			,('bodb_Message')
			,('bodb_TGRS')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES   ('SPVN\jerry.tran')
			,('SPVN\andrew.vu')
			,('SPVN\susan.le')
			,('SPVN\martin.tran')
			,('SPVN\shane.nguyen')
			,('SPVN\rocky.ping')
			,('SPVN\felix.nguyen')
			,('SPVN\lita.tang')
			,('SPVN\benji.duong')
			,('SPVN\henry.nguyen')
			,('SPVN\lucy.ho')
			,('SPVN\bill.nguyen')
			,('SPVN\joyce.pham')
			--,('SPVN\rita.bui')
			--,('SPVN\bob.duong')
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

--------------------------------------------------------------------------------------
-- Add Role for member
IF @@SERVERNAME NOT IN ( 'DB232', 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB232 or TESTDB061' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Terra'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\jerry.tran'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('bodb02')
			,('bodb_ACC')
			,('bodb_Report')
			,('bodb_Archive')
			,('bodb_Message')
			,('bodb_TGRS')

INSERT INTO @tmpMember (Name) 
	VALUES   ('SPVN\jerry.tran')
			,('SPVN\andrew.vu')
			,('SPVN\susan.le')
			,('SPVN\martin.tran')
			,('SPVN\shane.nguyen')
			,('SPVN\rocky.ping')
			,('SPVN\felix.nguyen')
			,('SPVN\lita.tang')
			,('SPVN\benji.duong')
			,('SPVN\henry.nguyen')
			,('SPVN\lucy.ho')
			,('SPVN\bill.nguyen')
			,('SPVN\joyce.pham')
			--,('SPVN\rita.bui')
			--,('SPVN\bob.duong')

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