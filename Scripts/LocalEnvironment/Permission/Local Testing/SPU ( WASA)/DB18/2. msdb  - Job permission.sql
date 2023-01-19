-- Create User
USE [msdb]
GO
IF  @@SERVERNAME NOT LIKE '%DB18' 
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu')
		 , ('spvn\terry.nguyen')
		 , ('spvn\casey.huynh')

		, ('spvn\john.ngo')
		, ('spvn\victoria.le')
		, ('spvn\jonathan.doan')

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
WAITFOR DELAY '00:00:01'


-- Add Role
 
SET @strUser = ''
SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentReaderRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO