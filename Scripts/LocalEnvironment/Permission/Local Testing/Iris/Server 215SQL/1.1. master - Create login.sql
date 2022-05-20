USE [master]
GO
-- Create Login
/*	Windows domain account:
	

*/
IF @@SERVERNAME <> 'DB215\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB215\SQLSERVER2008R2' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		,('spvn\dora.le'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\Neil.dao')
		,('spvn\jane.dinh'), ('spvn\harley.nguyen'), ('spvn\dory.vu')
		,('spvn\elio.nguyen')
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

