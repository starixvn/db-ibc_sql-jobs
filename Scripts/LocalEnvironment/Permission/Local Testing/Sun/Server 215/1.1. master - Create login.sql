USE [master]
GO
-- Create Login


IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or DevDB053 or TESTDB053' AS 'Error'
	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	--('spvn\kaylin.truong'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('spvn\nina.nguyen'),
	('spvn\roshan.nguyen'),
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

