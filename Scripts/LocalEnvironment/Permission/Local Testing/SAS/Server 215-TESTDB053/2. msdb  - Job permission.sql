-- Create User
USE [msdb]
 

IF @@SERVERNAME NOT IN ( 'DB215' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')

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

IF @@SERVERNAME NOT IN ( 'DB215' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')


SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO