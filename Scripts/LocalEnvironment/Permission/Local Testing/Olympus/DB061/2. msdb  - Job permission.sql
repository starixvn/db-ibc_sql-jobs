-- Create User
USE [msdb]
GO
/*
	Windows domain account:
	SPVN\jacob.phan
	SPVN\robert.tran
	SPVN\kaden.trinh
	SPVN\leo.vo
	SPVN\franklin.nguyen
	SPVN\alan.nguyen
	SPVN\kane.le
	SPVN\charles.nguyen
*/

IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		,('SPVN\leo.vo'), ('SPVN\franklin.nguyen')--, ('SPVN\alan.nguyen')
		--, ('SPVN\kane.le')
		, ('SPVN\charles.nguyen'), ('SPVN\raymond.le')
		,('SPVN\zane.trinh')
		,('SPVN\tyler.dang')
		,('SPVN\mira.nguyen'), ('SPVN\carlos.nguyen'), ('SPVN\liam.pham'), ('SPVN\johnny.thai'), ('SPVN\luca.duong'), ('SPVN\lita.tang')
		,('SPVN\martin.tran')
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

IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		,('SPVN\leo.vo'), ('SPVN\franklin.nguyen')--, ('SPVN\alan.nguyen')
		--, ('SPVN\kane.le')
		, ('SPVN\charles.nguyen'), ('SPVN\raymond.le')
		,('SPVN\zane.trinh')
		,('SPVN\tyler.dang')
		,('SPVN\mira.nguyen'), ('SPVN\carlos.nguyen'), ('SPVN\liam.pham'), ('SPVN\johnny.thai'), ('SPVN\luca.duong'), ('SPVN\lita.tang')
		,('SPVN\martin.tran')
SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO