-- Create User
USE [msdb]
GO
/*
	Windows domain account:
	spvn\jacob.phan
	spvn\robert.tran
	spvn\kaden.trinh
	spvn\leo.vo
	spvn\franklin.nguyen
	spvn\alan.nguyen
*/

IF @@SERVERNAME <> 'DB232\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB232\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen')

SELECT	@strUser = @strUser 
			+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]; '
			+ CHAR(13)
			+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
			+ CHAR(13)
FROM	@tmpMember t
	LEFT JOIN sys.database_principals s
		ON t.Name = s.name
WHERE	s.name IS NULL

--SELECT @strUser
EXEC (@strUser)
GO


-- Add Role
USE [msdb]
GO

IF @@SERVERNAME <> 'DB232\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB232\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

--SELECT @strUser

EXEC (@strUser)
GO