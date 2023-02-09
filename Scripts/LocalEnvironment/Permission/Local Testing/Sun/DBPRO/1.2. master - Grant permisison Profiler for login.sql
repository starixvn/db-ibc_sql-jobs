USE [master]
GO


-- Grant permisison Profiler for login
IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

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
	('SPVN\victor.nguyen'),
	('SPVN\Jasmine.le'),
	('SPVN\carly.tran')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

