-- Create User
USE [msdb]
GO
 
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS', 'DB62\DEVSITEDB','DB-60\DEVDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		, ('SPVN\franklin.nguyen') 
		, ('SPVN\charles.nguyen'), ('SPVN\raymond.le')
		,('SPVN\zane.trinh')
		,('SPVN\luca.duong')

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

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS', 'DB62\DEVSITEDB','DB-60\DEVDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		, ('SPVN\franklin.nguyen') 
		, ('SPVN\charles.nguyen'), ('SPVN\raymond.le')
		,('SPVN\zane.trinh')
		,('SPVN\luca.duong')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO