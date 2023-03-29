USE [master]
GO
-- Create Login
 
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')
			,('spvn\carter.ngo')
			,('spvn\rachel.vo')

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

