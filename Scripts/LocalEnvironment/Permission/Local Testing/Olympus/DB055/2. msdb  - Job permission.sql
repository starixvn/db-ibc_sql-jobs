-- Create User
USE [msdb]
GO
 
IF @@SERVERNAME NOT IN ( 'DB-61\DEVDB055' ,'TESTDB055' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan')
		, ('SPVN\robert.tran')
		, ('SPVN\kaden.trinh')
		, ('SPVN\franklin.nguyen')
		, ('SPVN\zane.trinh')
		, ('SPVN\luca.duong')
		, ('SPVN\Raymond.Le')
		, ('SPVN\Charles.Nguyen')
		, ('SPVN\Levi.Vu')
		, ('SPVN\Agnes.Tran')

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
waitfor delay '00:00:01'


-- Add Role
 

SET @strUser  = ''
 

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO