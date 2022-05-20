USE [master]
GO
/*	Windows domain account:
		SPVN\kos.nguyen
		SPVN\ricky.nguyen
		SPVN\jason.ly
		SPVN\james.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ('DB215','TESTDB053')
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\kos.nguyen'), ('SPVN\ricky.nguyen')
	--, ('SPVN\jason.ly')
		,('SPVN\james.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

