-- Create User
USE [msdb]
GO
/*	Windows domain account:
	spvn\ethan.nguyen
	spvn\andy.nguyen
	spvn\david.tran
	spvn\phillip.truong
	spvn\louis.nguyen
	spvn\kan.nguyen
	spvn\razor.nguyen
	spvn\alvin.nguyen
*/

IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DB233or TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\ethan.nguyen'), ('spvn\andy.nguyen'), ('spvn\david.tran')
		,('spvn\phillip.truong'), ('spvn\louis.nguyen'), ('spvn\kan.nguyen')
		,('spvn\razor.nguyen'), ('spvn\alvin.nguyen')
		,('spvn\jack.nguyen'), ('spvn\issac.le')

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

IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DB233 or TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\ethan.nguyen'), ('spvn\andy.nguyen'), ('spvn\david.tran')
		,('spvn\phillip.truong'), ('spvn\louis.nguyen'), ('spvn\kan.nguyen')
		,('spvn\razor.nguyen'), ('spvn\alvin.nguyen')
		,('spvn\jack.nguyen'), ('spvn\issac.le')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO