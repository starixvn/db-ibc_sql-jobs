USE [master]
GO
-- Create Login
IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\william.nguyen'),
	('SPVN\selina.dinh'),
	('SPVN\lionel.nguyen'),
	('SPVN\Winston.chau'),
	('SPVN\ruby.nguyen'),
	('SPVN\corbin.hoang'),
	('SPVN\jenny.phan'),
	('SPVN\harmony.huynh'),
	('SPVN\laura.nguyen'),
	('SPVN\nina.nguyen'),
	('SPVN\roshan.nguyen'),
	('SPVN\victor.nguyen')

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

