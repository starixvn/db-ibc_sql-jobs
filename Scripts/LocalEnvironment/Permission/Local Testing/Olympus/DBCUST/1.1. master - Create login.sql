USE [master]
GO
-- Create Login
/*	Windows domain account:
	SPVN\jacob.phan
	SPVN\robert.tran
	SPVN\kaden.trinh
	SPVN\leo.vo
	SPVN\franklin.nguyen
	SPVN\alan.nguyen
	SPVN\kane.le
	SPVN\tyler.dang
	SPVN\carlos.nguyen
*/
IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DB233 or TESTDBCUST' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		,('SPVN\leo.vo'), ('SPVN\franklin.nguyen')--, ('SPVN\alan.nguyen')
		--, ('SPVN\kane.le')
		, ('SPVN\tyler.dang'), ('SPVN\carlos.nguyen')
		,('SPVN\zane.trinh')
-- CREATE LOGIN [SPVN\nickname] FROM WINDOWS;  
SELECT @strLoginName = @strLoginName 
			+  'CREATE LOGIN [' + t.Name + '] FROM WINDOWS; ' 
			+ CHAR(13)
FROM @tmpMember t
	LEFT JOIN sys.server_principals s
		ON s.name = t.Name
WHERE	s.name IS NULL	


EXEC (@strLoginName)
GO

