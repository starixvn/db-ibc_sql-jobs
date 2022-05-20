-- Create User
USE [msdb]
GO
/*	Windows domain account:
	
*/

IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' ,'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		,('spvn\dora.le'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\Neil.dao')
		,('spvn\jane.dinh'), ('spvn\harley.nguyen'), ('spvn\dory.vu')
		,('spvn\elio.nguyen')
		,('spvn\Kenny.ho')

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

IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' ,'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		,('spvn\dora.le'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\Neil.dao')
		,('spvn\jane.dinh'), ('spvn\harley.nguyen'), ('spvn\dory.vu')
		,('spvn\elio.nguyen')
		,('spvn\Kenny.ho')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO