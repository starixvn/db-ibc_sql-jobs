USE [master]
GO
-- Create Login
/*	Windows domain account:
		spvn\kos.nguyen
		spvn\ricky.nguyen
		spvn\jason.ly
		spvn\james.nguyen
*/
IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kos.nguyen'), ('spvn\ricky.nguyen'), ('spvn\jason.ly')
		,('spvn\james.nguyen')

-- CREATE LOGIN [spvn\nickname] FROM WINDOWS;  
SELECT @strLoginName = @strLoginName 
			+  'CREATE LOGIN [' + t.Name + '] FROM WINDOWS; ' 
			+ CHAR(13)
FROM @tmpMember t
	LEFT JOIN sys.server_principals s
		ON s.name = t.Name
WHERE	s.name IS NULL	


EXEC (@strLoginName)
GO

