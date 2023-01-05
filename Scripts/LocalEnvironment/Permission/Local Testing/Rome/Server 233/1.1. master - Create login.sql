USE [master]
GO

IF @@SERVERNAME NOT IN ( 'db-60\devdbcust', 'TESTDBCUST' )
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\ethan.nguyen'), ('spvn\andy.nguyen'), ('spvn\david.tran')
		,('spvn\phillip.truong'), ('spvn\louis.nguyen'), ('spvn\kan.nguyen')
		,('spvn\razor.nguyen'), ('spvn\alvin.nguyen')
		,('spvn\jack.nguyen'), ('spvn\issac.le'),('spvn\aiden.nguyen')

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

