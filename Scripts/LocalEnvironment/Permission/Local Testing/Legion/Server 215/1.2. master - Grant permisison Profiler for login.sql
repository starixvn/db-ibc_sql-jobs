USE [master]
GO
 
-- Grant permisison Profiler for login

IF @@SERVERNAME NOT in ('DB215','TESTDB053')
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES   ('spvn\kos.nguyen')
			,('spvn\parsons.nguyen')
			,('spvn\hubert.duong')		
			,('spvn\howard.nguyen')		
			,('spvn\hogan.pham')	 
			,('spvn\steve.nguyen')		
			,('spvn\happy.duong')		
			,('spvn\kai.le')
			,('spvn\walter.nguyen')
			,('spvn\cody.nguyen')
			,('spvn\loki.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

