USE [master]
GO
-- Create Login
/*	Windows domain account:
		spvn\johnson.nguyen
		spvn\sophia.nguyen
		spvn\elodie.ho
		spvn\kathy.nguyen
		spvn\tina.vo
		spvn\helen.do
		spvn\percy.nguyen
		spvn\sol.le
		spvn\eden.dang
		spvn\bobby.nguyen
		spvn\tacy.nguyen
*/
IF @@SERVERNAME <> 'DB-60\DEVDBCUST'
BEGIN
	SELECT 'Must be run on DB-60\DEVDBCUST' AS 'Error'

	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		,('spvn\tacy.nguyen'), ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\tina.vo'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen')		

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

