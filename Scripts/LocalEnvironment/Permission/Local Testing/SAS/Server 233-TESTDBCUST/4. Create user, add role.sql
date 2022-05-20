 
-- Create User
IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DB233 or TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.sys.databases db
WHERE db.name not in ('master','tempdb','model','msdb', 'distribution', 'SSISDB','ReportServer', 'ReportServerTempDB', 'RedGate')
		AND db.state = 0 --ONLINE

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')


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
-- Add Role for member

IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DB233 or TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_SAS'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.sys.databases db
WHERE db.name not in ('master','tempdb','model','msdb', 'distribution', 'SSISDB','ReportServer', 'ReportServerTempDB', 'RedGate')
		AND db.state = 0 --ONLINE

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')

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