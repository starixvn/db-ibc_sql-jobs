USE [master]
GO
 

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB233', 'TESTDBCUST' )
BEGIN
	SELECT 'Wrong Server' AS 'Error'
	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('SPVN\nina.nguyen'),
	('SPVN\victor.nguyen'),
	('SPVN\Jasmine.le'),
	('SPVN\carly.tran')


SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

