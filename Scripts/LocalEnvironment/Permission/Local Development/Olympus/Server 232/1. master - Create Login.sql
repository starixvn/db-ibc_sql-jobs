USE [master]
GO
-- Create Login
/*	Windows domain account:
	spvn\jacob.phan
	spvn\robert.tran
	spvn\kaden.trinh
	spvn\leo.vo
	spvn\franklin.nguyen
	spvn\alan.nguyen
	spvn\kane.le
	spvn\charles.nguyen
	spvn\tyler.dang
	spvn\carlos.nguyen
*/
IF @@SERVERNAME <> 'DB232'
BEGIN
	SELECT 'Must be run on DB232' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen')
		, ('spvn\kane.le'), ('spvn\charles.nguyen'), ('spvn\raymond.le')
		, ('spvn\tyler.dang'), ('spvn\carlos.nguyen')

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

