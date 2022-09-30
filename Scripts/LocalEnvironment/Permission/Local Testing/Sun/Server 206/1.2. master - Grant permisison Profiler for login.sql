USE [master]
GO


-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS', 'TESTDB053\TESTSITEDB', 'DB-60\DEVDBTRANS', 'DB62\DEVSiteDB'  )
BEGIN
	SELECT 'Wrong server!'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\william.nguyen'),
	('SPVN\maia.le'),
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

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

