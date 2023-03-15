USE [master]
GO
 
IF @@SERVERNAME NOT IN ( 'DB-61\DEVDB055' ,'TESTDB055' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan')
		, ('SPVN\robert.tran')
		, ('SPVN\kaden.trinh')
		, ('SPVN\franklin.nguyen')
		, ('SPVN\zane.trinh')
		, ('SPVN\luca.duong')
		, ('SPVN\Raymond.Le')
		, ('SPVN\Charles.Nguyen')
		, ('SPVN\Levi.Vu')
		, ('SPVN\Agnes.Tran')

SELECT @strLoginName = @strLoginName 
			+  'CREATE LOGIN [' + t.Name + '] FROM WINDOWS; ' 
			+ CHAR(13)
FROM @tmpMember t
	LEFT JOIN sys.server_principals s
		ON s.name = t.Name
WHERE	s.name IS NULL	


EXEC (@strLoginName)
GO

