-- Create User
USE [msdb]
GO
 
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' , 'TESTDB053\TESTSITEDB', 'DB-60\DEVDBTRANS', 'DB62\DEVSiteDB' )
BEGIN
	SELECT 'Wrong server'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('spvn\nina.nguyen'),
	('spvn\roshan.nguyen'),
	('SPVN\victor.nguyen')

SELECT	@strUser = @strUser 
			+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]; '
			+ CHAR(13)
			+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
			+ CHAR(13)
FROM	@tmpMember t
	LEFT JOIN sys.database_principals s
		ON t.Name = s.name
WHERE	s.name IS NULL

EXEC (@strUser)
GO


-- Add Role
USE [msdb]
GO

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS', 'TESTDB053\TESTSITEDB', 'DB-60\DEVDBTRANS', 'DB62\DEVSiteDB'  )
BEGIN
	SELECT 'Wrong server'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('spvn\nina.nguyen'),
	('spvn\roshan.nguyen'),
	('SPVN\victor.nguyen')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO