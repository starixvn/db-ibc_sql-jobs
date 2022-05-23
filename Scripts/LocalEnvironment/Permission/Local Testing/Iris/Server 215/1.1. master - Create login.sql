USE [master]
GO
-- Create Login
/*	Windows domain account:
	

*/
IF @@SERVERNAME NOT IN ( 'DB215' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'),
		('spvn\dora.le'),
		('spvn\jane.dinh'),
		('spvn\megan.dinh'),
		('spvn\tommy.nguyen'),
		('spvn\Neil.dao'),
		('spvn\harley.nguyen'),
		('spvn\Mike.vu'),
		('spvn\kenny.ho')
		,('spvn\ariana.nguyen')
		,('spvn\benjamin.nguyen')

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

