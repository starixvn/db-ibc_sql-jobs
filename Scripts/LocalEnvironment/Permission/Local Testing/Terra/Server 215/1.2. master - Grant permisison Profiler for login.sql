USE [master]
GO
 

-- Grant permisison Profiler for login
IF @@SERVERNAME NOT IN ('DB-61\DevDB053','TESTDB053')
BEGIN
	SELECT 'Must be run on DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES   ('SPVN\jerry.tran')
			,('SPVN\andrew.vu')
			,('SPVN\susan.le')
			,('SPVN\martin.tran')
			,('SPVN\shane.nguyen')
			,('SPVN\rocky.ping')
			,('SPVN\felix.nguyen')
			,('SPVN\lita.tang')
			,('SPVN\benji.duong')
			,('SPVN\henry.nguyen')
			,('SPVN\lucy.ho')
			,('SPVN\bill.nguyen')
			,('spvn\joyce.pham')
			--,('SPVN\rita.bui')
			--,('SPVN\bob.duong')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

