USE [master]
GO
-- Create Login
/*	Windows domain account:
	

*/
IF @@SERVERNAME <> 'DB230\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB230\SQLSERVER2008R2' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'), ('spvn\rossa.nguyen'), ('spvn\justin.doan')
		,('spvn\dora.le'), ('spvn\lex.khuat'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\lana.nguyen')
		,('spvn\jane.dinh')

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

