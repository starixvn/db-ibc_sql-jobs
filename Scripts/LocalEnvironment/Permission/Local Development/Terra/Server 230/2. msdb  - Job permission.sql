-- Create User
USE [msdb]
GO
/*	Windows domain account:
	spvn\rocky.ping
	spvn\andrew.vu
	spvn\jerry.tran
	spvn\bob.duong
	spvn\martin.tran
	spvn\nancy.dao
	spvn\shane.nguyen
	spvn\kingsley.nguyen
	spvn\rita.bui
	spvn\felix.nguyen
	spvn\lita.tang
*/

IF @@SERVERNAME <> 'DB-60\DEVDBTRANS'
BEGIN
	SELECT 'Must be run on DB-60\DEVDBTRANS' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen')
		--, ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')
		,('spvn\Henry.Nguyen'), ('spvn\Lucy.Ho'),('spvn\benji.duong')
		,('spvn\Bill.Nguyen')
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

IF @@SERVERNAME <> 'DB-60\DEVDBTRANS'
BEGIN
	SELECT 'Must be run on DB-60\DEVDBTRANS' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen')
		--, ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')
		,('spvn\Henry.Nguyen'), ('spvn\Lucy.Ho'),('spvn\benji.duong')
		,('spvn\Bill.Nguyen')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO