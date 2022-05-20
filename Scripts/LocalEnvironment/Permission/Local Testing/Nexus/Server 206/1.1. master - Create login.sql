USE [master]
GO
-- Create Login
/*	Windows domain account:
	spvn\quinn.vo
	spvn\tim.trinh
	spvn\scofield.huynh

*/
IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\quinn.vo'), ('spvn\tim.trinh'), ('spvn\scofield.huynh'), ('spvn\oliver.dang'), ('spvn\drake.doi')

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

