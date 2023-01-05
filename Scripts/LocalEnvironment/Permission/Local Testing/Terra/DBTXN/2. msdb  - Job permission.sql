-- Create User
USE [msdb]
GO
 
IF @@SERVERNAME NOT LIKE '%DBTRANS' AND @@SERVERNAME NOT LIKE  '%SiteDB%'
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
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
 
SET @strUser = ''
SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO